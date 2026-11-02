# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Folder services" do # rubocop:disable RSpec/DescribeClass
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_test_cases manage_test_suites] }) }

  it "creates a subfolder" do
    parent = create(:tm_suite, project:)
    result = TestManagement::Suites::CreateService.new(user:).call(name: "Child", parent_id: parent.id, project:)

    expect(result).to be_success
    expect(result.result.parent).to eq(parent)
  end

  it "renames a folder" do
    suite = create(:tm_suite, project:)
    result = TestManagement::Suites::UpdateService.new(user:, model: suite).call(name: "Renamed")

    expect(result).to be_success
    expect(suite.reload.name).to eq("Renamed")
  end

  it "deletes a folder" do
    suite = create(:tm_suite, project:)
    expect(TestManagement::Suites::DeleteService.new(user:, model: suite).call).to be_success
    expect(TestManagement::Suite.where(id: suite.id)).to be_empty
  end

  it "refuses without manage_test_suites" do
    viewer = create(:user, member_with_permissions: { project => %i[view_test_cases] })
    result = TestManagement::Suites::CreateService.new(user: viewer).call(name: "X", project:)

    expect(result).not_to be_success
  end
end
