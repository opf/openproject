# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestCaseWorkPackage do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:other_work_package) { create(:work_package, project:) }

  let(:test_case) { create(:tm_test_case, project:) }

  it "links one test case to many work packages" do
    test_case.work_packages << work_package
    test_case.work_packages << other_work_package

    expect(test_case.reload.work_packages).to contain_exactly(work_package, other_work_package)
  end

  it "exposes the inverse association on WorkPackage" do
    create(:tm_test_case_work_package, test_case:, work_package:)

    expect(work_package.reload.tm_test_cases).to contain_exactly(test_case)
  end

  it "rejects duplicate links" do
    create(:tm_test_case_work_package, test_case:, work_package:)
    duplicate = build(:tm_test_case_work_package, test_case:, work_package:)

    expect(duplicate).not_to be_valid
  end

  it "removes links when the work package is destroyed" do
    create(:tm_test_case_work_package, test_case:, work_package: other_work_package)

    other_work_package.destroy

    expect(described_class.where(test_case:)).to be_empty
  end
end
