# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestCases::UpdateContract, "linked work packages" do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:hidden_project) { create(:project, enabled_module_names: %i[work_package_tracking]) }
  shared_let(:visible_wp) { create(:work_package, project:) }
  shared_let(:invisible_wp) { create(:work_package, project: hidden_project) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_test_cases edit_test_cases view_work_packages]
           })
  end

  let(:test_case) { create(:tm_test_case, project:) }

  def set_links(ids)
    TestManagement::TestCases::SetAttributesService
      .new(user:, model: test_case, contract_class: described_class)
      .call(work_package_ids: ids)
  end

  it "accepts work packages visible to the user" do
    result = set_links([visible_wp.id.to_s])

    expect(result).to be_success
    expect(test_case.linked_work_package_ids).to eq([visible_wp.id])
  end

  it "rejects work packages the user cannot see" do
    result = set_links([visible_wp.id.to_s, invisible_wp.id.to_s])

    expect(result).not_to be_success
    expect(result.errors.details[:work_package_ids]).to include(a_hash_including(error: :not_visible))
  end

  it "rejects IDs of work packages that do not exist" do
    result = set_links(["999999999"])

    expect(result).not_to be_success
    expect(result.errors.details[:work_package_ids]).to include(a_hash_including(error: :not_visible))
  end

  it "does not let a status-only user change links" do
    status_user = create(:user,
                         member_with_permissions: {
                           project => %i[view_test_cases change_test_case_status view_work_packages]
                         })
    result = TestManagement::TestCases::SetAttributesService
               .new(user: status_user, model: test_case, contract_class: described_class)
               .call(work_package_ids: [visible_wp.id.to_s])

    expect(result).not_to be_success
    expect(result.errors.details[:base]).to include(a_hash_including(error: :error_unauthorized))
  end
end
