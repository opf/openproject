# frozen_string_literal: true

require "spec_helper"
require_relative "../../../support/test_management_assistant"

RSpec.describe TestManagement::Assistant::ConfirmActionService do
  include_context "with test assistant provider"

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:permissions) { %i[view_test_cases view_test_runs add_test_runs add_test_cases use_test_assistant] }
  shared_let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  shared_let(:test_case) { create(:tm_test_case, project:, status: "ready") }

  let(:action) do
    TestManagement::Assistant::Actions.propose("create_test_run", { "name" => "Smoke", "test_case_ids" => [test_case.id] },
                                               user:, project:)
  end
  let(:message) do
    create(:tm_assistant_message, :answer, project:, user:, content: "Shall I?", action:, action_status: "proposed")
  end

  it "creates the run once, as the user, and records the result" do
    result = nil
    expect { result = described_class.new(user:, message:).call }.to change(TestManagement::TestRun, :count).by(1)

    expect(result).to be_success
    run = TestManagement::TestRun.last
    expect(run.name).to eq("Smoke")
    expect(message.reload).to have_attributes(action_status: "confirmed")
    expect(message.result_data["records"]).to eq([{ "type" => "test_run", "id" => run.id, "title" => "Smoke" }])

    expect { described_class.new(user:, message:).call }.not_to change(TestManagement::TestRun, :count)
  end

  it "only lets the owner confirm" do
    other = create(:user, member_with_permissions: { project => permissions })

    expect(described_class.new(user: other, message:).call).not_to be_success
    expect(message.reload.action_status).to eq("proposed")
  end

  it "re-checks permissions at confirmation time" do
    message
    user.members.each { |m| m.roles.each { |r| r.remove_permission!(:add_test_runs) } }

    expect { described_class.new(user: user.reload, message:).call }.not_to change(TestManagement::TestRun, :count)
    expect(message.reload.action_status).to eq("failed")
  end

  it "does not run proposals with problems or cancelled ones" do
    broken = create(:tm_assistant_message, :answer, project:, user:, action_status: "proposed",
                                                    action: action.merge("errors" => ["No test cases match."]))
    expect(described_class.new(user:, message: broken).call).not_to be_success

    expect(described_class.new(user:, message:).cancel).to be_success
    expect(message.reload.action_status).to eq("cancelled")
    expect(described_class.new(user:, message:).call).not_to be_success
    expect(TestManagement::TestRun.count).to eq(0)
  end

  it "creates proposed test cases" do
    cases = TestManagement::Assistant::Actions.propose(
      "create_test_cases",
      { "cases" => [{ "title" => "Logout", "steps" => [{ "action" => "Click logout", "expected_result" => "Signed out" }] }] },
      user:, project:
    )
    proposal = create(:tm_assistant_message, :answer, project:, user:, action: cases, action_status: "proposed")

    expect(described_class.new(user:, message: proposal).call).to be_success
    expect(TestManagement::TestCase.find_by(title: "Logout")).to have_attributes(status: "draft")
  end
end
