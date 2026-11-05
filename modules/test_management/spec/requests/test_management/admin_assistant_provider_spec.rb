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

RSpec.describe "Test management admin: AI providers", :disable_ssrf_filter, :skip_csrf, :webmock, type: :rails_request do
  shared_let(:admin) { create(:admin) }

  let(:base) { "/test_management/admin/assistant_providers" }
  let(:settings_path) { "/test_management/admin/settings#tm-assistant-providers" }
  let(:turbo) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }

  before { login_as(admin) }

  def providers = TestManagement::AssistantProvider.ordered.to_a

  describe "list" do
    it "shows the default provider first and never a key" do
      other = create(:tm_assistant_provider, name: "Mistral", preset: "mistral",
                                             base_url: "", model: "mistral-small-latest", api_key: "sk-m")
      default = create(:tm_assistant_provider, :default, name: "Gateway", api_key: "sk-list-secret")

      get "/test_management/admin/settings"

      expect(response).to have_http_status(:ok)
      page = Capybara.string(response.body)
      expect(page).to have_css("[data-test-selector='tm-assistant-providers-table'] tbody tr", count: 2)
      expect(page).to have_css("[data-test-selector='tm-assistant-provider-#{default.id}'] " \
                               "[data-test-selector='tm-assistant-provider-default']")
      expect(page).to have_css("[data-test-selector='tm-assistant-provider-make-default-#{other.id}']")
      expect(page).to have_no_css("[data-test-selector='tm-assistant-provider-make-default-#{default.id}']")
      expect(response.body).not_to include("sk-list-secret")
    end

    it "shows an empty state without providers" do
      get "/test_management/admin/settings"

      expect(Capybara.string(response.body)).to have_css("[data-test-selector='tm-assistant-providers-empty']")
    end
  end

  describe "new and create" do
    it "renders the form with the preset select first" do
      get "#{base}/new"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="refresh-on-form-changes"', 'name="name"', 'name="assistant_provider"',
                                       'name="user_models"', 'name="verify_model"', "tm-assistant-test-connection")
      expect(response.body.index('name="assistant_provider"')).to be < response.body.index('name="assistant_base_url"')
    end

    it "creates the first provider as the default with the key encrypted" do
      post base, params: { name: "Mistral", assistant_provider: "mistral", assistant_model_choice: "mistral-small-latest",
                           assistant_model: "", assistant_api_key: "sk-a-secret", user_models: "claude-b\nclaude-c",
                           verify_model: "0" }

      expect(response).to redirect_to(settings_path)
      provider = providers.sole
      expect(provider).to have_attributes(name: "Mistral", preset: "mistral", model: "mistral-small-latest",
                                          user_models: %w[claude-b claude-c], is_default: true)
      expect(provider.api_key_ciphertext).to be_present
      expect(provider.api_key_ciphertext).not_to include("sk-a-secret")
      expect(provider.config.api_key).to eq("sk-a-secret")
    end

    it "checks the model before saving when asked and keeps everything unsaved on failure" do
      stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
        .to_return(status: 404, body: { error: { message: "The model gpt-nope does not exist (sk-verify)" } }.to_json)

      post base, params: { name: "OpenRouter", assistant_provider: "openrouter", assistant_model: "openai/gpt-nope",
                           assistant_api_key: "sk-verify", verify_model: "1" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).not_to include("sk-verify")
      expect(providers).to be_empty
    end

    it "saves after a successful model check" do
      stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
        .to_return(status: 200, body: { choices: [{ message: { role: "assistant", content: "OK" } }] }.to_json)

      post base, params: { name: "OpenRouter", assistant_provider: "openrouter", assistant_model: "openai/gpt-4o-mini",
                           assistant_api_key: "sk-ok", verify_model: "1" }

      expect(providers.map(&:name)).to eq(%w[OpenAI])
    end

    it "refuses a duplicate name (case-insensitive) and an invalid base URL" do
      create(:tm_assistant_provider, name: "Gateway")

      post base, params: { name: "gateway", assistant_provider: "openrouter", assistant_base_url: "https://openrouter.ai/api/v1",
                           assistant_model: "m", assistant_auth_style: "none" }
      expect(response).to have_http_status(:unprocessable_entity)

      post base, params: { name: "Other", assistant_provider: "openrouter", assistant_base_url: "ftp://nope", assistant_model: "m" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(providers.size).to eq(1)
    end
  end

  describe "edit, default and delete" do
    let!(:first) { create(:tm_assistant_provider, :default, name: "First", api_key: "sk-first") }
    let!(:second) { create(:tm_assistant_provider, name: "Second", api_key: "sk-second") }

    it "keeps the stored key when the field is left empty and never renders it" do
      get "#{base}/#{second.id}/edit"
      expect(response.body).not_to include("sk-second")

      patch "#{base}/#{second.id}", params: { name: "Second", assistant_provider: "openrouter",
                                              assistant_model: "openai/gpt-4o", assistant_api_key: "", verify_model: "0" }

      expect(response).to redirect_to(settings_path)
      expect(second.reload.model).to eq("openai/gpt-4o")
      expect(second.config.api_key).to eq("sk-second")
    end

    it "requires a new key when the preset changes" do
      patch "#{base}/#{second.id}", params: { name: "Second", assistant_provider: "mistral",
                                              assistant_model: "mistral-small-latest",
                                              assistant_api_key: "", verify_model: "0" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(second.reload.preset).to eq("openrouter")
      expect(second.config.api_key).to eq("sk-second")
    end

    it "makes another provider the default" do
      post "#{base}/#{second.id}/make_default"

      expect(second.reload.is_default).to be(true)
      expect(first.reload.is_default).to be(false)
    end

    it "makes the next provider the default when the default is deleted" do
      delete "#{base}/#{first.id}"

      expect(TestManagement::AssistantProvider.exists?(first.id)).to be(false)
      expect(second.reload.is_default).to be(true)
    end
  end

  describe "provider_form and test_connection" do
    it "provider_form re-renders the fields for the chosen preset without saving" do
      post "#{base}/provider_form",
           params: { assistant_provider: "mistral", assistant_provider_was: "openrouter",
                     assistant_base_url: "https://openrouter.ai/api/v1", assistant_model: "openai/gpt-4o" }, headers: turbo

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('target="tm-assistant-provider-fields"', "https://api.mistral.ai/v1")
      expect(response.body).not_to include("openai/gpt-4o")
      expect(providers).to be_empty
    end

    it "lists the models as a select and never renders the key" do
      stub_request(:get, "https://openrouter.ai/api/v1/models/user")
        .to_return(status: 200, body: { data: [{ id: "openai/gpt-4o" }, { id: "openai/gpt-4o-mini" },
                                               { id: "text-embedding-3-small" }] }.to_json)

      patch "#{base}/test_connection",
            params: { assistant_provider: "openrouter", assistant_api_key: "sk-form-secret", assistant_model: "openai/gpt-4o-mini" },
            headers: turbo

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('target="tm-assistant-model-field"', "assistant_model_choice",
                                       '<option selected="selected" value="openai/gpt-4o-mini">', "tm-assistant-test-ok",
                                       "tm-assistant-catalogue-hint")
      expect(response.body).not_to include("text-embedding-3-small", "sk-form-secret")
      expect(WebMock).to have_requested(:get, "https://openrouter.ai/api/v1/models/user")
        .with(headers: { "Authorization" => "Bearer sk-form-secret" })
      expect(providers).to be_empty
    end

    it "uses the stored key of the edited provider when the field is blank" do
      provider = create(:tm_assistant_provider, name: "OpenRouter", preset: "openrouter", base_url: "", model: "openai/gpt-4o",
                                                api_key: "sk-stored")
      stub_request(:get, "https://openrouter.ai/api/v1/models/user").with(headers: { "Authorization" => "Bearer sk-stored" })
        .to_return(status: 200, body: { data: [{ id: "openai/gpt-4o" }, { id: "openai/gpt-4o-mini" }] }.to_json)

      post "#{base}/test_connection", params: { provider_id: provider.id, assistant_provider: "openrouter", assistant_api_key: "" },
                                      headers: turbo

      expect(response.body).to include("openai/gpt-4o-mini")
      expect(response.body).not_to include("sk-stored")
    end

    it "does not send another provider's stored key to a new preset" do
      provider = create(:tm_assistant_provider, name: "OpenRouter", preset: "openrouter", base_url: "", model: "openai/gpt-4o",
                                                api_key: "sk-openai-old")

      post "#{base}/test_connection", params: { provider_id: provider.id, assistant_provider: "mistral",
                                                assistant_api_key: "" }, headers: turbo

      expect(response.body).to include("tm-assistant-test-error", 'data-error-kind="invalid"')
      expect(WebMock).not_to have_requested(:any, /.*/)
    end

    it "reports auth errors without echoing the key" do
      stub_request(:get, "https://openrouter.ai/api/v1/models/user")
        .to_return(status: 401, body: { error: { message: "Incorrect API key provided: sk-bad-key" } }.to_json)

      post "#{base}/test_connection", params: { assistant_provider: "openrouter", assistant_api_key: "sk-bad-key" }, headers: turbo

      expect(response.body).to include("tm-assistant-test-error", 'data-error-kind="auth"')
      expect(response.body).not_to include("sk-bad-key")
    end

    it "without Turbo renders the whole form" do
      stub_request(:get, "https://openrouter.ai/api/v1/models/user").to_return(status: 200, body: { data: [{ id: "openai/gpt-4o" }] }.to_json)

      post "#{base}/test_connection", params: { assistant_provider: "openrouter", assistant_api_key: "k" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("tm-assistant-provider-select", "assistant_model_choice", 'name="name"')
    end
  end

  context "as a non-admin" do
    before { login_as(create(:user)) }

    it "refuses every action without calling a provider" do
      provider = create(:tm_assistant_provider, :default)

      get "#{base}/new"
      expect(response).to have_http_status(:forbidden)

      post base, params: { name: "X", assistant_provider: "openrouter", assistant_model: "m" }
      expect(response).to have_http_status(:forbidden)

      post "#{base}/#{provider.id}/make_default"
      expect(response).to have_http_status(:forbidden)

      post "#{base}/test_connection", params: { assistant_provider: "openrouter", assistant_api_key: "k" }, headers: turbo
      expect(response).to have_http_status(:forbidden)
      expect(WebMock).not_to have_requested(:any, /.*/)
      expect(providers.size).to eq(1)
    end
  end
end
