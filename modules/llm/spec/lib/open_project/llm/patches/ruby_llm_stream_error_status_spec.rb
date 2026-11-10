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

RSpec.describe OpenProject::Llm::Patches::RubyLLMStreamErrorStatus, :webmock do
  let(:base_url) { "https://example.com/v1" }
  let(:completions) { "#{base_url}/chat/completions" }

  def stream
    context = RubyLLM.context do |config|
      config.openai_api_base = base_url
      config.openai_api_key = "test-key"
      config.max_retries = 0
      config.logger = Logger.new(IO::NULL)
    end

    context.chat(model: "qwen3.6-27b", provider: :openai, assume_model_exists: true).ask("Hi") { nil }
  end

  def error_body(type, message: "Request failed")
    { error: { message:, type:, code: nil } }.to_json
  end

  it "applies to every provider" do
    expect(RubyLLM::Provider.ancestors).to include(described_class)
    expect(RubyLLM::Provider.private_method_defined?(:build_stream_error_response)).to be(true)
  end

  it "takes exactly the statuses that RubyLLM's error middleware classifies beyond a bad request" do
    classified = (400..599).select do |status|
      RubyLLM::ErrorMiddleware.parse_error(provider: nil, response: Struct.new(:status, :body).new(status, ""))
    rescue RubyLLM::BadRequestError
      false
    rescue RubyLLM::Error => e
      !e.instance_of?(RubyLLM::Error)
    end

    expect(classified).to match_array(described_class::CLASSIFIED_STATUSES)
  end

  it "reports a 429 whose error type the provider does not know as a rate limit" do
    stub_request(:post, completions).to_return(status: 429, body: error_body("requests"))

    expect { stream }.to raise_error(RubyLLM::RateLimitError)
  end

  it "reports a 401 as unauthorized" do
    stub_request(:post, completions).to_return(status: 401, body: error_body("invalid_request_error"))

    expect { stream }.to raise_error(RubyLLM::UnauthorizedError)
  end

  it "reports a 503 as an unavailable service" do
    stub_request(:post, completions).to_return(status: 503, body: error_body("invalid_request_error"))

    expect { stream }.to raise_error(RubyLLM::ServiceUnavailableError)
  end

  [413, 422].each do |status|
    it "still recognises a context length message on a #{status}" do
      body = error_body("invalid_request_error", message: "This model's maximum context length is 8192 tokens.")
      stub_request(:post, completions).to_return(status:, body:)

      expect { stream }.to raise_error(RubyLLM::ContextLengthExceededError)
    end
  end

  it "keeps the status from the body for an error event inside a successful stream" do
    stub_request(:post, completions)
      .to_return(status: 200, headers: { "Content-Type" => "text/event-stream" },
                 body: "data: #{error_body('invalid_request_error')}\n\n")

    expect { stream }.to raise_error(RubyLLM::BadRequestError)
  end
end
