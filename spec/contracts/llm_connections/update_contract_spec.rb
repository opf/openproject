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
require_relative "../shared/model_contract_shared_context"

RSpec.describe LlmConnections::UpdateContract, :check_errors_i18n, :llm_server_helpers, :webmock do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:admin) }
  let(:base_url) { "https://example.com/v1" }
  # Persisted, so that only the attributes an example changes are dirty. A
  # freshly built record has every factory attribute in changed_attributes,
  # which the contract would rightly reject as writes to non-writable columns.
  let(:connection) { create(:llm_connection, base_url: "https://previous.example/v1") }
  let(:contract) { described_class.new(connection, current_user) }

  let!(:models_request) { mock_llm_models_response(base_url) }

  before { connection.base_url = base_url }

  context "when the server answers with a model list" do
    include_examples "contract is valid"

    it "probes the server exactly once" do
      contract.validate

      expect(models_request).to have_been_made.once
    end
  end

  context "when the server rejects the credentials" do
    let!(:models_request) { mock_llm_models_response(base_url, response_code: 401) }

    include_examples "contract is invalid", api_key: :invalid_api_key
  end

  context "when the server cannot be reached" do
    let!(:models_request) { mock_llm_models_response(base_url, timeout: true) }

    include_examples "contract is invalid", base_url: :request_timed_out
  end

  # A server can speak the OpenAI API for chat and still not expose a model list:
  # OpenProject's own hosted gateway does exactly that. Blocking the save would
  # leave the administrator unable to configure a working connection at all.
  [404, 405, 501].each do |status|
    context "when the server answers #{status} for the model list" do
      let!(:models_request) { mock_llm_models_response(base_url, response_code: status) }

      include_examples "contract is valid"
    end
  end

  # Formats whose model list comes from the registry have nothing to probe here.
  context "with a format that does not discover models from the server" do
    let(:connection) { create(:llm_connection, api_format: "anthropic", base_url: "https://previous.example") }

    it "does not contact the base URL" do
      contract.validate

      expect(models_request).not_to have_been_made
    end
  end

  context "when the endpoint is not OpenAI-compatible" do
    let!(:models_request) { mock_llm_models_response(base_url, body: "<html>login</html>") }

    include_examples "contract is invalid", base_url: :not_openai_compatible
  end

  context "when the host is blocked by the SSRF policy" do
    before { allow_llm_host("something.else") }

    include_examples "contract is invalid", base_url: :ssrf_filtered

    it "does not contact the server" do
      contract.validate

      expect(models_request).not_to have_been_made
    end
  end

  context "when the base URL is not a URL at all" do
    let(:base_url) { "not a url" }

    # The validate_url gem always records :url in errors.details; the
    # message: :invalid_url option controls the rendered text, not the symbol.
    include_examples "contract is invalid", base_url: :url

    it "does not contact the server" do
      contract.validate

      expect(models_request).not_to have_been_made
    end
  end

  # Without the changed-attributes guard every unrelated save -- and every form
  # render that builds a model through SetAttributesService -- would fire an
  # outbound request at the LLM server.
  describe "the changed-attributes guard" do
    it "probes only when the credentials changed" do
      contract.validate
      expect(models_request).to have_been_made.once

      WebMock.reset_executed_requests!
      connection.save!
      contract.validate

      expect(models_request).not_to have_been_made
    end

    it "probes again when only the API key changed" do
      connection.save!
      WebMock.reset_executed_requests!

      connection.api_key = "sk-rotated"
      contract.validate

      expect(models_request).to have_been_made.once
    end

    # Switching the dialect is switching the server, even at the same URL: a
    # connection previously talking to a registry-backed provider must be proven
    # again when it becomes OpenAI-compatible.
    it "probes when only the API format changed to an OpenAI-compatible one" do
      connection.update_columns(api_format: "anthropic", base_url: base_url)
      connection.reload.api_format = "openai"

      expect(contract.validate).to be(true)
      expect(models_request).to have_been_made.once
    end

    it "does not probe when only the enabled flag changed" do
      connection.save!
      WebMock.reset_executed_requests!

      connection.enabled = true

      expect(contract.validate).to be(true)
      expect(models_request).not_to have_been_made
    end
  end

  describe "default model selection" do
    let(:connection) { create(:llm_connection, :with_models, base_url:) }

    context "with a model the server offers" do
      before { connection.default_chat_model_id = "bge-m3" }

      include_examples "contract is valid"
    end

    context "with a model the server does not offer" do
      before { connection.default_chat_model_id = "not-there" }

      include_examples "contract is invalid", default_chat_model_id: :not_available
    end
  end
end
