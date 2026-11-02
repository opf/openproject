# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestCases::DeleteService do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases delete_test_cases]
           })
  end
  let(:test_case) { create(:tm_test_case, project:) }

  it "soft-deletes the test case and keeps the id reserved" do
    suite = create(:tm_suite, project:)
    test_case.update!(suite:)

    result = described_class.new(user:, model: test_case).call

    expect(result).to be_success
    test_case.reload
    expect(test_case.deleted_at).to be_present
    expect(test_case.deleted_from_suite_id).to eq(suite.id)
    expect(test_case.deleted_from_suite_path).to eq(suite.path_name)
    expect(test_case.events.order(:id).last.action).to eq("deleted")
    expect(TestManagement::TestCase.not_deleted.where(id: test_case.id)).to be_empty
  end
end
