# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper
require "socket"
require "zlib"

RSpec.describe Llm::SsrfFilteredAdapter do
  let(:server) { TCPServer.new("127.0.0.1", 0) }
  let(:base_url) { "http://127.0.0.1:#{server.addr[1]}/v1" }
  let(:connection) { create(:llm_connection, base_url:, api_key: "sk-test-key") }
  let(:requests) { Queue.new }
  let(:session) { Llm::Session.for(connection, timeout: 5, max_retries: 0) }

  after { server.close }

  def serve(&)
    Thread.new do
      client = server.accept
      requests << read_request(client)
      yield(client)
    ensure
      client&.close
    end
  end

  def connection_attempted?
    server.accept_nonblock.close
    true
  rescue IO::WaitReadable
    false
  end

  def read_request(client)
    head = +""
    while (line = client.gets) && line != "\r\n"
      head << line
    end
    headers = head.lines.drop(1).map { |line| line.chomp.split(": ", 2) }
    length = headers.find { |name, _| name.casecmp?("content-length") }&.last.to_i

    { headers:, body: client.read(length) }
  end

  def respond_json(client, body, status: "200 OK")
    payload = body.to_json
    client.write "HTTP/1.1 #{status}\r\nContent-Type: application/json\r\n" \
                 "Content-Length: #{payload.bytesize}\r\nConnection: close\r\n\r\n#{payload}"
  end

  def write_chunk(client, data)
    client.write "#{data.bytesize.to_s(16)}\r\n#{data}\r\n"
    client.flush
  end

  def sse_delta(content)
    "data: #{{ choices: [{ index: 0, delta: { content: } }] }.to_json}\n\n"
  end

  def chat_body(content)
    LlmServerHelpers::DEFAULT_CHAT_BODY.merge(
      choices: [{ index: 0, message: { role: "assistant", content: }, finish_reason: "stop" }]
    )
  end

  context "without an allowlist entry for the private address" do
    it "refuses a chat completion before connecting to the server" do
      expect { session.chat("qwen3.6-27b").ask("ping") }.to raise_error(Llm::Errors::SsrfError)
      expect(connection_attempted?).to be(false)
    end

    it "refuses an embedding request before connecting" do
      expect { session.embed("hello", model: "bge-m3") }.to raise_error(Llm::Errors::SsrfError)
      expect(connection_attempted?).to be(false)
    end

    it "refuses a hostname that resolves to the private address before connecting" do
      connection.update_column(:base_url, "http://localhost:#{server.addr[1]}/v1")

      expect { session.chat("qwen3.6-27b").ask("ping") }.to raise_error(Llm::Errors::SsrfError)
      expect(connection_attempted?).to be(false)
    end
  end

  it "reports a host that does not resolve as a transient connection failure" do
    connection.update_column(:base_url, "http://llm.does-not-exist.invalid/v1")

    expect { session.chat("qwen3.6-27b").ask("ping") }.to raise_error do |error|
      expect(error).to be_a(Llm::Errors::ConnectionError)
      expect(Llm::Errors.transient?(error)).to be(true)
    end
  end

  context "with the private address on the allowlist", with_ssrf_ip_allowlist: ["127.0.0.1/32"] do
    it "answers a chat completion" do
      serve { |client| respond_json(client, chat_body("pong")) }

      expect(session.chat("qwen3.6-27b").ask("ping").content).to eq("pong")
    end

    it "streams each chunk as it arrives" do
      first_chunk_seen = Queue.new
      serve do |client|
        client.write "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nTransfer-Encoding: chunked\r\n\r\n"
        write_chunk(client, sse_delta("Good"))
        next unless first_chunk_seen.pop(timeout: 2)

        write_chunk(client, sse_delta(" morning"))
        write_chunk(client, "data: [DONE]\n\n")
        client.write "0\r\n\r\n"
      end

      chunks = []
      answer = session.chat("qwen3.6-27b").ask("ping") do |chunk|
        chunks << chunk.content
        first_chunk_seen << true
      end

      expect(chunks).to eq(["Good", " morning"])
      expect(answer.content).to eq("Good morning")
    end

    it "decompresses a gzip-encoded stream before handing it on" do
      compressed = Zlib.gzip([sse_delta("Good"), sse_delta(" morning"), "data: [DONE]\n\n"].join)
      serve do |client|
        client.write "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nContent-Encoding: gzip\r\n" \
                     "Transfer-Encoding: chunked\r\n\r\n"
        compressed.bytes.each_slice((compressed.bytesize / 2) + 1) { |slice| write_chunk(client, slice.pack("C*")) }
        client.write "0\r\n\r\n"
      end

      chunks = []
      answer = session.chat("qwen3.6-27b").ask("ping") { |chunk| chunks << chunk.content }

      expect(chunks).to eq(["Good", " morning"])
      expect(answer.content).to eq("Good morning")
    end

    it "does not resend a completion when the server drops the connection", :aggregate_failures do
      Thread.new do
        2.times do
          client = server.accept
          requests << read_request(client)
          client.close
        end
      end

      expect { session.chat("qwen3.6-27b").ask("ping") }.to raise_error(Llm::Errors::ConnectionError)
      expect(requests.size).to eq(1)
    end

    it "reports a stream the server rejects with its HTTP status" do
      serve do |client|
        respond_json(client, { error: { message: "Slow down", type: "requests" } }, status: "429 Too Many Requests")
      end

      expect { session.chat("qwen3.6-27b").ask("ping") { nil } }.to raise_error(Llm::Errors::RateLimitedError)
    end

    it "times out a server that does not answer" do
      serve { sleep 3 }

      expect { Llm::Session.for(connection, timeout: 1, max_retries: 0).chat("qwen3.6-27b").ask("ping") }
        .to raise_error(Llm::Errors::TimeoutError)
    end

    it "lets a custom header replace the Authorization header" do
      connection.update!(custom_headers: { "Authorization" => "Bearer gateway-token" })
      serve { |client| respond_json(client, chat_body("pong")) }

      session.chat("qwen3.6-27b").ask("ping")

      authorization = requests.pop[:headers].select { |name, _| name.casecmp?("authorization") }
      expect(authorization.map(&:last)).to eq(["Bearer gateway-token"])
    end
  end
end
