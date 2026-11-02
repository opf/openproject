# frozen_string_literal: true

require "spec_helper"

# Provider picker in the Test Assistant header (0021): users pick one of the saved providers and one
# of its offered models; Generate and Chat use (and record) that choice.
RSpec.describe "Test management assistant: provider picker", :disable_ssrf_filter, :skip_csrf, :webmock, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_test_cases add_test_cases use_test_assistant view_work_packages] })
  end
  shared_let(:admin) { create(:admin) }

  let!(:gateway) do
    create(:tm_assistant_provider, :default, name: "Gateway", base_url: "https://gw.example.test/v1", model: "gw-small",
                                             user_models: %w[gw-large], api_key: "sk-gw-secret")
  end
  let!(:second) do
    create(:tm_assistant_provider, name: "Second", base_url: "https://second.example.test/v1", model: "second-model",
                                   api_key: "sk-second-secret")
  end

  let(:base) { "/projects/#{project.identifier}/test_management/assistant" }
  let(:current_user) { user }

  before do
    allow(TestManagement::Assistant::GenerateJob).to receive(:perform_later)
    allow(TestManagement::Assistant::ChatJob).to receive(:perform_later)
    login_as(current_user)
  end

  def reply(content)
    { status: 200, headers: { "Content-Type" => "application/json" },
      body: { choices: [{ message: { role: "assistant", content: }, finish_reason: "stop" }] }.to_json }
  end

  describe "the header" do
    it "shows the default provider and every offered model, never URLs or keys" do
      get base

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("tm-assistant-provider-picker", "✨ Gateway · gw-small", "Gateway · gw-large",
                                       "Second · second-model", "Ask an administrator to add providers")
      expect(response.body).not_to include("Add new provider…", "sk-gw-secret", "gw.example.test", "second.example.test")
    end

    it "offers administrators “Add new provider…” returning to this page" do
      login_as(admin)
      get base, params: { tab: "chat" }

      expect(response.body).to include("tm-assistant-provider-add", "Add new provider…",
                                       "/test_management/admin/assistant_providers/new?return_to=")
      expect(response.body).not_to include("Ask an administrator to add providers")
    end

    it "is hidden without saved providers" do
      TestManagement::AssistantProvider.delete_all
      get base

      expect(response.body).not_to include("tm-assistant-provider-picker")
    end
  end

  describe "select_provider" do
    it "stores the choice per user and keeps the tab" do
      patch "#{base}/provider", params: { selection: "#{second.id}:second-model", tab: "chat" }

      expect(response).to redirect_to("#{base}?tab=chat")
      choice = TestManagement::Assistant::ProviderChoice.for(user)
      expect(choice.provider).to eq(second)
      expect(TestManagement::Assistant::ProviderChoice.for(admin).provider).to eq(gateway)

      get base
      expect(response.body).to include("✨ Second · second-model")
    end

    it "accepts an offered model of a provider" do
      patch "#{base}/provider", params: { selection: "#{gateway.id}:gw-large" }

      expect(TestManagement::Assistant::ProviderChoice.for(user).model).to eq("gw-large")
    end

    it "rejects a model the provider does not offer and unknown providers" do
      patch "#{base}/provider", params: { selection: "#{gateway.id}:gpt-secret-model" }
      expect(flash[:error]).to eq("This provider or model is not available.")

      patch "#{base}/provider", params: { selection: "999999:x" }
      expect(flash[:error]).to be_present
      expect(TestManagement::Assistant::ProviderChoice.for(user).provider).to eq(gateway)
    end

    it "needs the assistant permission" do
      login_as(create(:user, member_with_permissions: { project => %i[view_test_cases] }))
      patch "#{base}/provider", params: { selection: "#{second.id}:second-model" }

      expect(response).to have_http_status(:forbidden)
    end

    it "falls back to the default provider when the picked one is deleted" do
      TestManagement::Assistant::ProviderChoice.select!(user, "#{second.id}:second-model")
      second.destroy

      expect(TestManagement::Assistant::ProviderChoice.for(user).provider).to eq(gateway)
    end
  end

  describe "Generate and Chat use the choice" do
    before { TestManagement::Assistant::ProviderChoice.select!(user, "#{gateway.id}:gw-large") }

    it "records the choice on the generation and the job calls that provider and model" do
      post "#{base}/generations", params: { generation: { source_type: "text", source: { text: "Users can log in." } } }

      generation = TestManagement::AssistantGeneration.last
      expect(generation).to have_attributes(provider_id: gateway.id, chosen_model: "gw-large")

      cases = { cases: [{ title: "Login works", type: "positive", priority: "high",
                          steps: [{ action: "Log in", expected_result: "Dashboard" }] }] }.to_json
      stub = stub_request(:post, "https://gw.example.test/v1/chat/completions")
        .with(headers: { "Authorization" => "Bearer sk-gw-secret" }) { JSON.parse(it.body)["model"] == "gw-large" }
        .to_return(reply(cases))

      # The user picks another provider before the job runs: the job keeps the choice made when sending.
      TestManagement::Assistant::ProviderChoice.select!(user, "#{second.id}:second-model")
      User.execute_as(user) { TestManagement::Assistant::GenerateService.new(generation:).call }

      expect(stub).to have_been_requested
      expect(generation.reload.provider_model).to eq("Gateway · gw-large")
    end

    it "records the choice on the chat question and answer" do
      post "#{base}/messages", params: { content: "How many cases are ready?" }

      question, answer = TestManagement::AssistantMessage.order(:id).last(2)
      expect([question.provider_id, question.chosen_model]).to eq([gateway.id, "gw-large"])
      expect([answer.provider_id, answer.chosen_model]).to eq([gateway.id, "gw-large"])
    end
  end
end
