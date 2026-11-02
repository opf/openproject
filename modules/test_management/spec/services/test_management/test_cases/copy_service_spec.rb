# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestCases::CopyService do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_test_cases add_test_cases edit_test_cases view_work_packages]
           })
  end
  shared_let(:suite) { create(:tm_suite, project:, name: "Target") }
  shared_let(:work_package) { create(:work_package, project:) }

  before { login_as(user) }

  it "copies content, steps, labels and work packages and clears the automation reference" do
    source = create(:tm_test_case, :with_steps, project:,
                                                title: "Source",
                                                automated: true,
                                                automation_reference: "tests/a.spec.ts#a",
                                                priority: "high",
                                                status: "draft")
    label = create(:tm_label, project:, name: "smoke")
    source.test_case_labels.create!(label:)
    source.test_case_work_packages.create!(work_package:)

    call = described_class.new(user:, model: source).call(suite_id: suite.id)

    expect(call).to be_success
    copy = call.result
    expect(copy.id).not_to eq(source.id)
    expect(copy.title).to eq("Source")
    expect(copy.suite_id).to eq(suite.id)
    expect(copy.priority).to eq("high")
    expect(copy.status).to eq("draft")
    expect(copy.automated).to be(true)
    expect(copy.automation_reference).to be_nil
    expect(copy.steps.count).to eq(2)
    expect(copy.labels.map(&:name)).to eq(%w[smoke])
    expect(copy.work_packages).to contain_exactly(work_package)
  end
end
