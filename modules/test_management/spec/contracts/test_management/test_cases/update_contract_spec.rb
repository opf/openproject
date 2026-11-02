# frozen_string_literal: true

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe TestManagement::TestCases::UpdateContract do
  include_context "ModelContract shared context"

  # work_package_tracking: without it no work package of the project is visible, so the
  # link visibility check would (correctly) reject the new link.
  let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  let(:test_case) { create(:tm_test_case, project:, status: "draft") }
  let(:contract) { described_class.new(test_case, current_user) }

  context "with edit_test_cases" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases edit_test_cases] }) }

    before { test_case.title = "New title" }

    it_behaves_like "contract is valid"
  end

  context "with only change_test_case_status" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_test_cases change_test_case_status] })
    end

    context "when only the status changes" do
      before { test_case.status = "ready" }

      it_behaves_like "contract is valid"
    end

    context "when the title changes too" do
      before do
        test_case.status = "ready"
        test_case.title = "Sneaky"
      end

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "when labels change together with the status" do
      before do
        test_case.status = "ready"
        test_case.test_case_labels.build(label: build(:tm_label, project:))
      end

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "when work package links change together with the status" do
      before do
        test_case.status = "ready"
        test_case.test_case_work_packages.build(work_package: create(:work_package, project:))
      end

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end
  end

  context "with only change_test_case_status and step changes (review fix)" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_test_cases change_test_case_status] })
    end
    let!(:step) { create(:tm_test_step, test_case:) }

    before { test_case.reload.status = "ready" }

    context "when an existing step is edited" do
      before { test_case.steps.to_a.first.action = "Rewritten" }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "when a step is added" do
      before { test_case.steps.build(position: 2, action: "Extra") }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "when a step is removed" do
      before { test_case.steps.to_a.first.mark_for_destruction }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end
  end

  context "with only link_test_cases_to_work_packages" do
    let(:current_user) do
      create(:user,
             member_with_permissions: { project => %i[view_test_cases view_work_packages link_test_cases_to_work_packages] })
    end

    context "when only the links change" do
      before { test_case.test_case_work_packages.build(work_package: create(:work_package, project:)) }

      it_behaves_like "contract is valid"
    end

    context "when the status changes too" do
      before do
        test_case.status = "ready"
        test_case.test_case_work_packages.build(work_package: create(:work_package, project:))
      end

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end
  end

  context "with a folder of another project" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases edit_test_cases] }) }

    before { test_case.suite = create(:tm_suite) }

    it_behaves_like "contract is invalid", suite_id: :invalid
  end

  context "without any edit permission" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }

    before { test_case.status = "ready" }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end
end
