# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/test_management_assistant"

RSpec.describe "Test management assistant (Generate | Chat)", :skip_csrf, type: :rails_request do
  include_context "with test assistant provider"

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:permissions) do
    %i[view_test_cases add_test_cases view_test_runs add_test_runs use_test_assistant view_work_packages]
  end
  shared_let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  shared_let(:no_assistant) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }
  shared_let(:admin) { create(:admin) }
  shared_let(:test_case) { create(:tm_test_case, project:, title: "Login works") }

  let(:current_user) { user }
  let(:base) { "/projects/#{project.identifier}/test_management/assistant" }

  before do
    allow(TestManagement::Assistant::GenerateJob).to receive(:perform_later)
    allow(TestManagement::Assistant::ChatJob).to receive(:perform_later)
    login_as(current_user)
  end

  describe "page and menu" do
    it "shows the Generate tab by default, the Chat tab on request, and the menu entry" do
      get base
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-test-selector="tm-assistant-switch"', "tm-assistant-generate-submit",
                                       "Test Assistant")

      get base, params: { tab: "chat" }
      expect(response.body).to include("tm-assistant-chat-form")
    end

    it "redirects the former Generate and Chat placeholders permanently" do
      get "/projects/#{project.identifier}/test_management/placeholders/generate"
      expect(response).to have_http_status(:moved_permanently)
      expect(response.location).to end_with("/projects/#{project.identifier}/test_management/assistant?tab=generate")

      get "/projects/#{project.identifier}/test_management/placeholders/chat"
      expect(response).to have_http_status(:moved_permanently)
      expect(response.location).to end_with("/projects/#{project.identifier}/test_management/assistant?tab=chat")
    end

    it "403s without the permission and 404s when the project switched the assistant off" do
      login_as(no_assistant)
      get base
      expect(response).to have_http_status(:forbidden)

      login_as(user)
      TestManagement::ProjectSetting.for_project(project).update!(enable_test_assistant: "0")
      get base
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "without a provider" do
    before { allow(Setting).to receive(:plugin_openproject_test_management).and_return({}) }

    it "tells administrators how to configure it" do
      login_as(admin)
      get base

      expect(response.body).to include("tm-assistant-configure-provider")
      expect(response.body).not_to include("tm-assistant-unavailable")
    end

    it "shows a disabled state to everybody else and refuses to generate" do
      get base
      expect(response.body).to include("tm-assistant-unavailable")
      expect(response.body).not_to include("tm-assistant-configure-provider")

      post "#{base}/generations", params: { generation: { source_type: "text", source: { text: "Login" } } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(TestManagement::AssistantGeneration.count).to eq(0)
    end
  end

  describe "Generate" do
    it "queues a generation, shows it pending, then the drafts, and saves selected drafts" do
      post "#{base}/generations", params: {
        generation: { source_type: "text", source: { text: "Users can log in." },
                      options: { count: "2", types: %w[positive negative], label_names: "ai" } }
      }
      generation = TestManagement::AssistantGeneration.last
      expect(response).to redirect_to("#{base}/generations/#{generation.id}")
      expect(TestManagement::Assistant::GenerateJob).to have_received(:perform_later).with(generation.id)

      get "#{base}/generations/#{generation.id}"
      expect(response.body).to include("tm-assistant-generation-pending")
      expect(response.body).to include('data-controller="test-management--generation-status"')
      expect(response.body).to include("tm-draft-results")
      expect(response.body).to include("data-test-management--generation-status-frame-url-value")
      expect(response.body).not_to include('http-equiv="refresh"')

      generation.update!(status: "done", drafts: build(:tm_assistant_generation, :done).drafts)
      get "#{base}/generations/#{generation.id}"
      expect(response.body).to include("Reset with a valid link", "Expired link is rejected")

      get "#{base}/generations/#{generation.id}", headers: { "Turbo-Frame" => "tm-draft-results" }
      expect(response.body).to include("tm-draft-results", "Reset with a valid link", "Expired link is rejected")

      post "#{base}/generations/#{generation.id}/save", params: {
        label_names: "ai",
        drafts: {
          "0" => { selected: "1", title: "Edited reset", type: "positive", priority: "high",
                   steps: { "0" => { action: "Request", expected_result: "Mail" } } },
          "1" => { selected: "0", title: "Not saved", priority: "low",
                   steps: { "0" => { action: "x", expected_result: "y" } } }
        }
      }
      expect(response).to have_http_status(:redirect)
      expect(TestManagement::TestCase.where(title: "Edited reset")).to exist
      expect(TestManagement::TestCase.where(title: "Not saved")).not_to exist
    end

    it "re-renders the form with errors" do
      post "#{base}/generations", params: { generation: { source_type: "text", source: { text: "" } } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("tm-assistant-generate-submit")
    end

    it "404s for another user's generation" do
      other = create(:tm_assistant_generation, :done, project:, user: create(:user))

      get "#{base}/generations/#{other.id}"
      expect(response).to have_http_status(:not_found)
      post "#{base}/generations/#{other.id}/save", params: { drafts: {} }
      expect(response).to have_http_status(:not_found)
    end

    describe "status polling" do
      let!(:generation) { create(:tm_assistant_generation, :running, project:, user:) }

      it "returns JSON for each state with Cache-Control: no-store" do
        get "#{base}/generations/#{generation.id}/status", as: :json
        expect(response).to have_http_status(:ok)
        expect(response.headers["Cache-Control"]).to include("no-store")
        expect(response.parsed_body).to include(
          "state" => "running",
          "step" => "preparing_source",
          "step_index" => 2,
          "step_count" => 4,
          "progress" => { "done" => 1, "total" => 4 },
          "error" => nil
        )

        expect(response.parsed_body["started_at"]).to be_present
        expect(response.parsed_body["updated_at"]).to be_present
        expect(response.parsed_body["message"]).to be_present

        generation.update!(status: "done", drafts: build(:tm_assistant_generation, :done).drafts,
                           progress_done: 2, progress_total: 2,
                           usage: { "prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30 })
        get "#{base}/generations/#{generation.id}/status", as: :json
        expect(response.parsed_body).to include(
          "state" => "succeeded",
          "usage" => { "prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30 }
        )

        generation.update!(status: "failed", error: "boom", drafts: [])
        get "#{base}/generations/#{generation.id}/status", as: :json
        expect(response.parsed_body).to include("state" => "failed", "error" => "boom")

        generation.update!(status: "cancelled", error: nil)
        get "#{base}/generations/#{generation.id}/status", as: :json
        expect(response.parsed_body["state"]).to eq("cancelled")

        generation.update!(status: "queued", progress_step: "queued",
                           progress_done: nil, progress_total: nil)
        get "#{base}/generations/#{generation.id}/status", as: :json
        expect(response.parsed_body).to include(
          "state" => "queued",
          "step" => "queued",
          "step_index" => 1,
          "progress" => { "done" => 0, "total" => 4 }
        )
      end

      it "403s without permission and 404s for another user's generation" do
        login_as(no_assistant)
        get "#{base}/generations/#{generation.id}/status", as: :json
        expect(response).to have_http_status(:forbidden)

        login_as(user)
        other = create(:tm_assistant_generation, :running, project:, user: create(:user))
        get "#{base}/generations/#{other.id}/status", as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "cancel and retry" do
      it "cancels a pending generation and can retry it" do
        generation = create(:tm_assistant_generation, :running, project:, user:)

        post "#{base}/generations/#{generation.id}/cancel", as: :json
        expect(response).to have_http_status(:ok)
        expect(response.headers["Cache-Control"]).to include("no-store")
        expect(response.parsed_body["state"]).to eq("cancelled")
        expect(generation.reload).to be_cancelled

        post "#{base}/generations/#{generation.id}/retry"
        expect(response).to redirect_to("#{base}/generations/#{generation.id}")
        expect(generation.reload.status).to eq("queued")
        expect(TestManagement::Assistant::GenerateJob).to have_received(:perform_later).with(generation.id)
      end
    end
  end

  describe "Chat" do
    it "asks a question and shows it with the pending answer" do
      post "#{base}/messages", params: { content: "How many cases are ready?" }

      expect(response).to redirect_to("#{base}?tab=chat#tm-assistant-chat-form")
      expect(TestManagement::AssistantMessage.of(user, project).pluck(:role, :state))
        .to eq([%w[user done], %w[assistant pending]])
      get base, params: { tab: "chat" }
      expect(response.body).to include("How many cases are ready?")
    end

    it "creates nothing before Confirm, then creates the run; Cancel and Clear work" do
      action = TestManagement::Assistant::Actions.propose("create_test_run",
                                                          { "name" => "Chat run", "test_case_ids" => [test_case.id] },
                                                          user:, project:)
      proposal = create(:tm_assistant_message, :answer, project:, user:, action:, action_status: "proposed")
      get base, params: { tab: "chat" }
      expect(response.body).to include("tm-assistant-message-#{proposal.id}")
      expect(TestManagement::TestRun.count).to eq(0)

      post "#{base}/messages/#{proposal.id}/confirm"
      run = TestManagement::TestRun.find_by(name: "Chat run")
      expect(run).to be_present
      get base, params: { tab: "chat" }
      expect(response.body).to include("tm-assistant-record-test_run-#{run.id}")

      other = create(:tm_assistant_message, :answer, project:, user:, action:, action_status: "proposed")
      post "#{base}/messages/#{other.id}/cancel"
      expect(other.reload.action_status).to eq("cancelled")

      delete "#{base}/messages"
      expect(TestManagement::AssistantMessage.of(user, project)).to be_empty
    end

    it "keeps conversations per user" do
      foreign = create(:tm_assistant_message, :answer, project:, user: admin, content: "Admin secret answer",
                                                       action: { "name" => "create_milestone", "params" => { "name" => "X" },
                                                                 "preview" => [], "errors" => [] },
                                                       action_status: "proposed")
      get base, params: { tab: "chat" }
      expect(response.body).not_to include("Admin secret answer")

      post "#{base}/messages/#{foreign.id}/confirm"
      expect(response).to have_http_status(:not_found)
    end
  end
end

RSpec.describe "Test management admin settings: AI providers", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }

  before { login_as(admin) }

  after { Setting.plugin_openproject_test_management = {} }

  it "stores the key encrypted and never renders it" do
    post "/test_management/admin/assistant_providers", params: {
      name: "Gateway", assistant_provider: "custom", assistant_base_url: "https://llm.example.com/v1",
      assistant_model: "test-model", assistant_api_key: "sk-admin-secret"
    }
    expect(response).to have_http_status(:redirect)
    expect(TestManagement::Assistant::ProviderConfig.current).to be_configured
    expect(TestManagement::AssistantProvider.sole.api_key_ciphertext).not_to include("sk-admin-secret")

    get "/test_management/admin/settings"
    expect(response.body).to include("Gateway")
    expect(response.body).not_to include("sk-admin-secret")
  end

  it "saves the general settings without touching the providers" do
    provider = create(:tm_assistant_provider, :default)

    patch "/test_management/admin/settings", params: { assistant_base_url: "ftp://ignored", assistant_model: "ignored" }

    expect(response).to have_http_status(:redirect)
    expect(provider.reload.model).to eq("test-model")
    expect(Setting.plugin_openproject_test_management.to_h).not_to have_key("assistant_model")
  end

  it "is for administrators only" do
    login_as(create(:user))
    get "/test_management/admin/settings"

    expect(response).to have_http_status(:forbidden)
  end
end
