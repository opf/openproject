# frozen_string_literal: true

require "spec_helper"
require_relative "../../../support/test_management_assistant"

RSpec.describe TestManagement::Assistant::GenerateService, :disable_ssrf_filter, :webmock do
  include_context "with test assistant provider"

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_test_cases use_test_assistant view_work_packages] })
  end
  shared_let(:work_package) do
    create(:work_package, project:, subject: "Password reset", description: "Users get a reset link by email.")
  end

  let(:generation) do
    create(:tm_assistant_generation, project:, user:, source_type: "work_package",
                                     source: { "work_package_id" => work_package.id.to_s })
  end
  let(:cases_json) do
    { cases: [{ title: "Reset with valid link", type: "positive", priority: "high",
                steps: [{ action: "Request reset", expected_result: "Mail sent" }] },
              { title: "Reset with expired link", type: "negative", priority: "low",
                steps: [{ action: "Open old link", expected_result: "Error shown" }] }] }.to_json
  end

  def run_job = User.execute_as(user) { described_class.new(generation:).call }

  it "sends the fenced work package to the provider and stores normalized drafts" do
    stub_llm(llm_reply(content: "Here you go:\n```json\n#{cases_json}\n```",
                       usage: { prompt_tokens: 111, completion_tokens: 222, total_tokens: 333,
                                completion_tokens_details: { reasoning_tokens: 40 } }))

    run_job

    generation.reload
    expect(generation.status).to eq("done")
    expect(generation.provider_model).to eq("llm.example.com / test-model")
    expect(generation.drafts.pluck("title")).to eq(["Reset with valid link", "Reset with expired link"])
    expect(generation).to have_attributes(progress_done: 2, progress_total: 2)
    expect(generation.usage).to eq("prompt_tokens" => 111, "completion_tokens" => 222,
                                   "total_tokens" => 333, "reasoning_tokens" => 40)
    system, prompt = llm_request_bodies.first["messages"].pluck("content")
    expect(system).to include("senior QA engineer", "at most 2", "ISTQB")
    expect(llm_request_bodies.first).to include("reasoning" => { "effort" => "low" })
    expect(prompt).to include("Password reset", "Users get a reset link by email.")
  end

  it "bumps progress as each draft is stored and walks the named steps" do
    stub_llm(llm_reply(content: cases_json))
    progress = []
    allow_any_instance_of(TestManagement::AssistantGeneration).to receive(:update!).and_wrap_original do |method, *args| # rubocop:disable RSpec/AnyInstance
      result = method.call(*args)
      progress << [generation.reload.progress_step, generation.progress_done, generation.progress_total, generation.status]
      result
    end

    run_job

    expect(progress.map(&:first)).to include("preparing_source", "waiting_for_model", "writing_drafts")
    expect(progress).to include(["writing_drafts", 1, 2, "running"], ["writing_drafts", 2, 2, "running"],
                                ["writing_drafts", 2, 2, "done"])
  end

  it "stops early when cancelled between drafts" do
    stub_llm(llm_reply(content: cases_json))
    allow_any_instance_of(TestManagement::AssistantGeneration).to receive(:update!).and_wrap_original do |method, *args| # rubocop:disable RSpec/AnyInstance
      result = method.call(*args)
      attrs = args.first || {}
      if attrs[:progress_done] == 1
        generation.update_columns(status: "cancelled", updated_at: Time.current)
      end
      result
    end

    run_job

    expect(generation.reload).to have_attributes(status: "cancelled", drafts: [])
  end

  it "fails with the provider and model named when the provider errors" do
    stub_request(:post, assistant_completions_url).to_return(status: 500, body: "{}")

    run_job

    expect(generation.reload).to have_attributes(status: "failed")
    expect(generation.error).to start_with("llm.example.com / test-model: HTTP 500")
  end

  it "fails when the reply holds no usable drafts" do
    stub_llm(llm_reply(content: "I cannot help with that."))

    run_job

    expect(generation.reload).to have_attributes(status: "failed")
    expect(generation.error).to include("no usable test cases")
    expect(generation.error).to include("I cannot help with that.")
  end

  describe TestManagement::Assistant::GenerateJob do
    it "runs queued generations only and turns unexpected errors into a failed generation" do
      stub_llm(llm_reply(content: cases_json))
      described_class.perform_now(generation.id)
      expect(generation.reload.status).to eq("done")

      done_at = generation.updated_at
      described_class.perform_now(generation.id)
      expect(generation.reload.updated_at).to eq(done_at)

      broken = create(:tm_assistant_generation, project:, user:)
      allow(TestManagement::Assistant::GenerateService).to receive(:new).and_raise(ArgumentError)
      described_class.perform_now(broken.id)
      expect(broken.reload).to have_attributes(status: "failed")
      expect(broken.error).to include("ArgumentError")
    end

    it "does not start a cancelled generation" do
      generation.update!(status: "cancelled")
      stub_llm(llm_reply(content: cases_json))
      described_class.perform_now(generation.id)
      expect(generation.reload.status).to eq("cancelled")
    end
  end
end
