# frozen_string_literal: true

require "spec_helper"
require Rails.root.join("spec/services/principals/replace_references_context")

RSpec.describe Principals::ReplaceReferencesService, "#call", type: :model do
  subject(:service_call) { instance.call(from: principal, to: to_principal) }

  shared_let(:other_user) { create(:user, firstname: "other user") }
  shared_let(:principal) { create(:user, firstname: "old principal") }
  shared_let(:to_principal) { create(:user, firstname: "new principal") }

  let(:instance) { described_class.new }

  context "with TestManagement::TestCase" do
    it_behaves_like "rewritten record", :tm_test_case, :author_id
    it_behaves_like "rewritten record", :tm_test_case, :assigned_to_id
    it_behaves_like "rewritten record", :tm_test_case, :updated_by_id
  end

  context "with TestManagement::TestCaseEvent" do
    shared_let(:test_case) { create(:tm_test_case) }

    it_behaves_like "rewritten record", TestManagement::TestCaseEvent, :user_id do
      let(:attributes) do
        {
          test_case_id: test_case.id,
          action: "'created'",
          created_at: "NOW()"
        }
      end
    end
  end

  context "with TestManagement::TestRun" do
    it_behaves_like "rewritten record", :tm_test_run, :author_id
    it_behaves_like "rewritten record", :tm_test_run, :assigned_to_id
    it_behaves_like "rewritten record", :tm_test_run, :finished_by_id
  end

  context "with TestManagement::TestRunCase" do
    it_behaves_like "rewritten record", :tm_test_run_case, :assigned_to_id
  end

  context "with TestManagement::TestResult" do
    it_behaves_like "rewritten record", :tm_test_result, :user_id
  end

  context "with TestManagement::AutomationImport" do
    it_behaves_like "rewritten record", :tm_automation_import, :user_id
  end

  context "with TestManagement::CiConnection" do
    it_behaves_like "rewritten record", :tm_ci_connection, :created_by_id
  end

  context "with TestManagement::TestRunIteration" do
    it_behaves_like "rewritten record", :tm_test_run_iteration, :created_by_id
  end

  context "with TestManagement::Milestone" do
    it_behaves_like "rewritten record", :tm_milestone, :created_by_id
  end

  context "with TestManagement::TestPlan" do
    it_behaves_like "rewritten record", :tm_test_plan, :author_id
    it_behaves_like "rewritten record", :tm_test_plan, :assigned_to_id
    it_behaves_like "rewritten record", :tm_test_plan, :finished_by_id
  end

  context "with TestManagement::TestPlanEntry" do
    it_behaves_like "rewritten record", :tm_test_plan_entry, :assigned_to_id
  end
end
