# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::WorkPackageTesting do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages view_test_cases view_test_runs] })
  end

  let(:work_package) { create(:work_package, project:) }
  let(:case_a) { create(:tm_test_case, project:, title: "A") }
  let(:case_b) { create(:tm_test_case, project:, title: "B") }

  subject(:testing) { described_class.new(work_package, user:) }

  before do
    create(:tm_test_case_work_package, test_case: case_a, work_package:)
    create(:tm_test_case_work_package, test_case: case_b, work_package:)
    create(:tm_test_case, project:, title: "Not linked")
  end

  it "returns the linked, visible cases in id order" do
    expect(testing.test_cases).to eq([case_a, case_b])
    expect(described_class.count_for(work_package, user:)).to eq(2)
  end

  it "skips soft-deleted cases" do
    case_b.soft_delete!
    expect(testing.test_cases).to eq([case_a])
  end

  it "returns nothing for a user without view_test_cases" do
    stranger = create(:user)
    expect(described_class.count_for(work_package, user: stranger)).to eq(0)
  end

  it "maps each case to its latest run case" do
    first = create(:tm_test_run, project:)
    second = create(:tm_test_run, project:)
    create(:tm_test_run_case, test_run: first, test_case: case_a, status: "passed")
    latest = create(:tm_test_run_case, test_run: second, test_case: case_a, status: "failed")

    expect(testing.latest_run_cases).to eq(case_a.id => latest)
  end
end
