# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestCases::RestoreService do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_test_cases edit_test_cases delete_test_cases]
           })
  end
  shared_let(:suite) { create(:tm_suite, project:, name: "Folder A") }

  let(:test_case) { create(:tm_test_case, project:, suite:, title: "Gone") }

  before { login_as(user) }

  def restore(model, suite_id: :keep)
    described_class.new(user:, model:).call(suite_id:)
  end

  it "restores into the previous folder when it still exists" do
    TestManagement::TestCases::DeleteService.new(user:, model: test_case).call

    expect(restore(test_case.reload)).to be_success
    expect(test_case.reload).not_to be_deleted
    expect(test_case.suite_id).to eq(suite.id)
    expect(test_case.events.order(:id).last.action).to eq("restored")
  end

  it "restores unfiled cases without asking for a folder" do
    unfiled = create(:tm_test_case, project:, suite: nil)
    TestManagement::TestCases::DeleteService.new(user:, model: unfiled).call

    expect(restore(unfiled.reload)).to be_success
    expect(unfiled.reload.suite_id).to be_nil
  end

  it "requires a folder when the previous suite was removed" do
    TestManagement::TestCases::DeleteService.new(user:, model: test_case).call
    suite.destroy!
    deleted = test_case.reload

    expect(deleted.restore_needs_folder?).to be(true)
    expect(restore(deleted)).not_to be_success

    other = create(:tm_suite, project:, name: "Folder B")
    expect(restore(deleted, suite_id: other.id)).to be_success
    expect(deleted.reload.suite_id).to eq(other.id)
  end
end
