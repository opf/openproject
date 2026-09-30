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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Llm::Errors do
  def rubyllm_response(status)
    instance_double(Faraday::Env, status:)
  end

  describe ".translate" do
    it "maps an unauthorized response onto an authentication error" do
      translated = described_class.translate(RubyLLM::UnauthorizedError.new(rubyllm_response(401), "nope"))

      expect(translated).to be_a(Llm::Errors::AuthenticationError)
    end

    it "maps a forbidden response onto an authentication error" do
      translated = described_class.translate(RubyLLM::ForbiddenError.new(rubyllm_response(403), "nope"))

      expect(translated).to be_a(Llm::Errors::AuthenticationError)
    end

    it "maps an exceeded context window onto a context length error" do
      translated = described_class.translate(RubyLLM::ContextLengthExceededError.new(rubyllm_response(400), "too long"))

      expect(translated).to be_a(Llm::Errors::ContextLengthError)
      expect(translated.status).to eq(400)
    end

    it "maps throttling onto a rate limited error" do
      translated = described_class.translate(RubyLLM::RateLimitError.new(rubyllm_response(429), "slow down"))

      expect(translated).to be_a(Llm::Errors::RateLimitedError)
    end

    it "maps a bad request onto an api error carrying the status" do
      translated = described_class.translate(RubyLLM::BadRequestError.new(rubyllm_response(400), "bad"))

      expect(translated).to be_a(Llm::Errors::ApiError)
      expect(translated.status).to eq(400)
    end

    # A server that does not implement the endpoint answers 404/405/501, which
    # RubyLLM's middleware raises as a bare Error. This is the path that tells a
    # probe "this model cannot do that" rather than "the server is broken".
    it "maps an unimplemented endpoint onto an api error carrying the status" do
      translated = described_class.translate(RubyLLM::Error.new(rubyllm_response(404), "not found"))

      expect(translated).to be_a(Llm::Errors::ApiError)
      expect(translated.status).to eq(404)
    end

    it "maps a misconfiguration onto a configuration error" do
      expect(described_class.translate(RubyLLM::ConfigurationError.new("missing key")))
        .to be_a(Llm::Errors::ConfigurationError)
      expect(described_class.translate(RubyLLM::ModelNotFoundError.new("no such model")))
        .to be_a(Llm::Errors::ConfigurationError)
    end

    it "maps transport failures onto connection errors" do
      expect(described_class.translate(Faraday::TimeoutError.new("timeout")))
        .to be_a(Llm::Errors::TimeoutError)
      expect(described_class.translate(Faraday::ConnectionFailed.new("refused")))
        .to be_a(Llm::Errors::ConnectionError)
      expect(described_class.translate(JSON::ParserError.new("unexpected token")))
        .to be_a(Llm::Errors::ParseError)
    end

    it "passes an already translated error through untouched" do
      original = Llm::Errors::SsrfError.new("Host resolves to a blocked address")

      expect(described_class.translate(original)).to be(original)
    end

    # An OpenAI-compatible gateway echoes the submitted Authorization header,
    # upstream provider URLs and internal hostnames in its error payloads, and
    # RubyLLM puts that payload straight into the exception message.
    it "never carries the upstream message into the translated error" do
      secret = "Bearer sk-super-secret upstream=http://10.0.0.5:8000"

      http_errors = [RubyLLM::Error, RubyLLM::BadRequestError, RubyLLM::ForbiddenError,
                     RubyLLM::ContextLengthExceededError, RubyLLM::OverloadedError,
                     RubyLLM::PaymentRequiredError, RubyLLM::RateLimitError, RubyLLM::ServerError,
                     RubyLLM::ServiceUnavailableError, RubyLLM::UnauthorizedError]
      plain_errors = [RubyLLM::ConfigurationError, RubyLLM::ModelNotFoundError]

      errors = http_errors.map { |klass| klass.new(rubyllm_response(400), secret) } +
               plain_errors.map { |klass| klass.new(secret) }

      errors.each do |error|
        message = described_class.translate(error).message

        expect(message).not_to include("sk-super-secret")
        expect(message).not_to include("10.0.0.5")
      end
    end
  end

  describe ".wrap" do
    it "returns the block's value when nothing is raised" do
      expect(described_class.wrap { :fine }).to be(:fine)
    end

    it "re-raises a RubyLLM failure as an Llm::Errors" do
      expect { described_class.wrap { raise RubyLLM::UnauthorizedError.new(rubyllm_response(401), "nope") } }
        .to raise_error(Llm::Errors::AuthenticationError)
    end
  end

  describe "the Llm::Client aliases" do
    it "resolve to the same classes, so existing rescues keep working" do
      expect(Llm::Client::Error).to be(Llm::Errors::Error)
      expect(Llm::Client::ApiError).to be(Llm::Errors::ApiError)
      expect(Llm::Client::SsrfError).to be(Llm::Errors::SsrfError)
    end
  end
end
