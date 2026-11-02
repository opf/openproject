# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Milestones::CreateContract do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[work_package_tracking]) }
  shared_let(:manager) do
    create(:user,
           member_with_permissions: { project => %i[view_test_cases view_test_runs manage_test_milestones view_work_packages] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] }) }

  let(:milestone) { build(:tm_milestone, project:, name: "Release 2.0") }
  let(:user) { manager }

  def errors
    contract = described_class.new(milestone, user)
    contract.validate
    contract.errors
  end

  it "is valid for a manager" do
    expect(errors).to be_empty
  end

  it "needs manage_test_milestones" do
    expect(described_class.new(milestone, viewer).tap(&:validate).errors.details[:base]).to include(error: :error_unauthorized)
  end

  it "is invalid when milestones are disabled in the project" do
    create(:tm_project_setting, project:).update!(enable_milestones: false)
    expect(errors.details[:base]).to include(error: :tm_milestones_disabled)
  end

  it "accepts the project's versions and rejects unshared foreign ones" do
    milestone.version = create(:version, project:)
    expect(errors).to be_empty

    milestone.version = create(:version, project: other_project, sharing: "none")
    expect(errors.details[:version]).to include(error: :invalid)
  end

  it "rejects links to work packages the user cannot see" do
    hidden = create(:work_package, project: other_project)
    milestone.milestone_work_packages.build(work_package: hidden)
    expect(errors.details[:work_package_ids]).to include(a_hash_including(error: :not_visible))
  end
end

RSpec.describe TestManagement::Milestones::UpdateContract do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:manager) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs manage_test_milestones] })
  end

  it "keeps the project read-only" do
    milestone = create(:tm_milestone, project:)
    milestone.project = other_project
    contract = described_class.new(milestone, manager)
    contract.validate
    expect(contract.errors.details[:project]).to include(error: :error_readonly)
  end
end
