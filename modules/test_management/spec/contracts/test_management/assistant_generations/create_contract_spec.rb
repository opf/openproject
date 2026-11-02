# frozen_string_literal: true

require "spec_helper"
require_relative "../../../support/test_management_assistant"

RSpec.describe TestManagement::AssistantGenerations::CreateService, "contract" do
  include_context "with test assistant provider"

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_test_cases use_test_assistant view_work_packages] })
  end
  shared_let(:work_package) { create(:work_package, project:, subject: "Password reset") }
  shared_let(:hidden_work_package) { create(:work_package, subject: "Somewhere else") }
  shared_let(:suite) { create(:tm_suite, project:) }

  let(:current_user) { user }
  let(:params) do
    { project:, source_type: "work_package", source: { work_package_id: work_package.id },
      options: { count: "4", types: %w[positive edge], suite_id: suite.id, label_names: "ai, regression" } }
  end

  before { allow(TestManagement::Assistant::GenerateJob).to receive(:perform_later) }

  def call(overrides = {}) = described_class.new(user: current_user).call(params.merge(overrides))

  def base_errors(result) = result.errors.details[:base].pluck(:error)

  it "creates a queued generation for the user and enqueues the job" do
    result = call

    expect(result).to be_success
    generation = result.result
    expect(generation).to have_attributes(status: "queued", user:, source_type: "work_package")
    expect(generation.count).to eq(4)
    expect(generation.label_names).to eq(%w[ai regression])
    expect(TestManagement::Assistant::GenerateJob).to have_received(:perform_later).with(generation.id)
  end

  it "rejects an invisible work package, empty or long text, unknown PR URLs and bad options" do
    expect(call(source: { work_package_id: hidden_work_package.id })).to be_failure
    expect(call(source_type: "text", source: { text: " " })).to be_failure
    expect(call(source_type: "code", source: { code: "x" * 20_001 })).to be_failure
    expect(call(source_type: "pull_request", source: { url: "https://github.com/x/y/pull/1" })).to be_failure
    expect(call(options: { count: "21" })).to be_failure
    expect(call(options: { types: %w[nonsense] })).to be_failure
    expect(call(options: { suite_id: create(:tm_suite).id })).to be_failure
  end

  context "without the permission" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases view_work_packages] }) }

    it { expect(base_errors(call)).to include(:error_unauthorized) }
  end

  it "needs a configured provider" do
    allow(Setting).to receive(:plugin_openproject_test_management).and_return({})

    expect(base_errors(call)).to include(:tm_assistant_not_configured)
  end

  it "is off when the project disabled the assistant" do
    create(:tm_project_setting, project:, enable_test_assistant: "0")

    expect(base_errors(call)).to include(:tm_assistant_disabled)
  end

  it "allows at most three running generations per user" do
    3.times { call }

    expect(base_errors(call)).to include(:tm_assistant_busy)
  end
end

RSpec.describe TestManagement::AssistantMessages::CreateService, "contract" do
  include_context "with test assistant provider"

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_test_cases use_test_assistant] }) }

  before { allow(TestManagement::Assistant::ChatJob).to receive(:perform_later) }

  def ask(content, as: user) = described_class.new(user: as).call(project:, content:)

  it "stores the question, a pending answer and enqueues the job" do
    expect(ask("How many cases?")).to be_success

    answer = TestManagement::AssistantMessage.of(user, project).find_by(role: "assistant")
    expect(answer.state).to eq("pending")
    expect(TestManagement::Assistant::ChatJob).to have_received(:perform_later).with(answer.id)
  end

  it "allows one open question at a time and checks length and permission" do
    ask("first")

    expect(ask("second")).to be_failure
    TestManagement::AssistantMessage.update_all(state: "done")
    expect(ask(" ")).to be_failure
    expect(ask("x" * 4001)).to be_failure
    expect(ask("hi", as: create(:user, member_with_permissions: { project => %i[view_test_cases] }))).to be_failure
  end
end
