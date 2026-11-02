# frozen_string_literal: true

require "spec_helper"

RSpec.describe Principals::DeleteJob, "Test Management", type: :model do
  subject(:job) { described_class.perform_now(principal) }

  shared_let(:deleted_user) { create(:deleted_user) }

  let(:principal) { create(:user) }
  let(:project) { create(:project) }

  it "rewrites attribution references and removes cascade-owned rows" do
    test_case = create(:tm_test_case, project:, author: principal, assigned_to: principal, updated_by: principal)
    event = TestManagement::TestCaseEvent.create!(test_case:, user: principal, action: "created")
    run = create(:tm_test_run, project:, author: principal, assigned_to: principal, finished_by: principal)
    run_case = create(:tm_test_run_case, test_run: run, assigned_to: principal)
    result = create(:tm_test_result, run_case:, user: principal)
    import = create(:tm_automation_import, test_run: run, project:, user: principal)
    connection = create(:tm_ci_connection, project:, created_by: principal)
    iteration = create(:tm_test_run_iteration, test_run: run, created_by: principal)
    milestone = create(:tm_milestone, project:, created_by: principal)
    plan = create(:tm_test_plan, project:, author: principal, assigned_to: principal, finished_by: principal)
    entry = create(:tm_test_plan_entry, test_plan: plan, assigned_to: principal)
    preference = TestManagement::UserPreference.for(principal).tap(&:save!)
    generation = create(:tm_assistant_generation, project:, user: principal)
    message = create(:tm_assistant_message, project:, user: principal)

    job

    expect(test_case.reload).to have_attributes(
      author: deleted_user,
      assigned_to: deleted_user,
      updated_by: deleted_user
    )
    expect(event.reload.user).to eq(deleted_user)
    expect(run.reload).to have_attributes(
      author: deleted_user,
      assigned_to: deleted_user,
      finished_by: deleted_user
    )
    expect(run_case.reload.assigned_to).to eq(deleted_user)
    expect(result.reload.user).to eq(deleted_user)
    expect(import.reload.user).to eq(deleted_user)
    expect(connection.reload.created_by).to eq(deleted_user)
    expect(iteration.reload.created_by).to eq(deleted_user)
    expect(milestone.reload.created_by).to eq(deleted_user)
    expect(plan.reload).to have_attributes(
      author: deleted_user,
      assigned_to: deleted_user,
      finished_by: deleted_user
    )
    expect(entry.reload.assigned_to).to eq(deleted_user)

    expect(TestManagement::UserPreference.exists?(preference.id)).to be(false)
    expect(TestManagement::AssistantGeneration.exists?(generation.id)).to be(false)
    expect(TestManagement::AssistantMessage.exists?(message.id)).to be(false)
  end
end
