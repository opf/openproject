# frozen_string_literal: true

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe TestManagement::TestRuns::CreateContract do
  include_context "ModelContract shared context"

  let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_runs add_test_runs] }) }
  let(:test_run) { build(:tm_test_run, project:, author: current_user) }
  let(:contract) { described_class.new(test_run, current_user) }

  it_behaves_like "contract is valid"

  context "without add_test_runs" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_runs execute_test_runs] }) }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  context "with an assignee who is not a project member" do
    before { test_run.assigned_to = create(:user) }

    it_behaves_like "contract is invalid", assigned_to: :invalid
  end

  context "with a project member as assignee" do
    before { test_run.assigned_to = current_user }

    it_behaves_like "contract is valid"
  end

  context "with a reference the user cannot see" do
    before { test_run.test_run_work_packages.build(work_package: create(:work_package)) }

    it_behaves_like "contract is invalid", work_package_ids: :not_visible
  end

  context "with a visible reference" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_test_runs add_test_runs view_work_packages] })
    end

    before { test_run.test_run_work_packages.build(work_package: create(:work_package, project:)) }

    it_behaves_like "contract is valid"
  end

  context "with a selected case from another project" do
    before { test_run.selected_case_ids = [create(:tm_test_case).id] }

    it_behaves_like "contract is invalid", selected_case_ids: :invalid
  end

  context "with a dynamic filter using a foreign label" do
    before do
      test_run.selection_mode = "dynamic"
      test_run.filter_options = { "label_ids" => [create(:tm_label).id] }
    end

    it_behaves_like "contract is invalid", filter_options: :invalid
  end

  context "with a dynamic filter using a foreign folder" do
    before do
      test_run.selection_mode = "dynamic"
      test_run.filter_options = { "suite_ids" => [create(:tm_suite).id] }
    end

    it_behaves_like "contract is invalid", filter_options: :invalid
  end
end
