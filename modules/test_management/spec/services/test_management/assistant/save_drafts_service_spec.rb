# frozen_string_literal: true

require "spec_helper"
require_relative "../../../support/test_management_assistant"

RSpec.describe TestManagement::Assistant::SaveDraftsService do
  include_context "with test assistant provider"

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases add_test_cases use_test_assistant view_work_packages]
           })
  end
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:suite) { create(:tm_suite, project:, name: "Accounts") }

  let(:generation) { create(:tm_assistant_generation, :done, project:, user:) }
  let(:drafts) { generation.drafts }

  subject(:result) { described_class.new(user:, generation:).call(drafts:) }

  it "saves selected drafts as draft cases with steps, folder and labels" do
    generation.update!(options: generation.options.merge("suite_id" => suite.id.to_s, "label_names" => ["ai"]))
    drafts.last["selected"] = "0"

    expect(result).to be_success
    test_case = result.cases.sole
    expect(test_case).to have_attributes(title: "Reset with a valid link", status: "draft", suite:)
    expect(test_case.steps.map(&:expected_result)).to eq(["An email is sent"])
    expect(test_case.labels.map(&:name)).to eq(["ai"])
    expect(generation.reload.saved_ids).to eq([test_case.id])
  end

  it "applies inline edits and links the source work package" do
    generation.update!(source_type: "work_package", source: { "work_package_id" => work_package.id.to_s })
    drafts.first["title"] = "Edited title"

    expect(result).to be_success
    expect(result.cases.map(&:title)).to include("Edited title")
    expect(result.cases.first.work_packages).to contain_exactly(work_package)
  end

  it "keeps a pull request source as a description note" do
    generation.update!(source_type: "pull_request", source: { "url" => "https://github.com/my-org/shop/pull/12" })

    expect(result.cases.first.description).to include("https://github.com/my-org/shop/pull/12")
    expect(result.cases.first.automation_reference).to be_blank
  end

  it "saves nothing when the cases are invalid (all or nothing)" do
    foreign_folder = create(:tm_suite)

    expect { expect(described_class.new(user:, generation:).call(drafts:, suite_id: foreign_folder.id)).not_to be_success }
      .not_to change(TestManagement::TestCase, :count)
  end

  it "needs at least one selected draft" do
    drafts.each { it["selected"] = "0" }

    expect(result).not_to be_success
  end

  it "refuses other users' generations and users without 'Add test cases'" do
    other = create(:user, member_with_permissions: { project => %i[view_test_cases add_test_cases use_test_assistant] })
    expect(described_class.new(user: other, generation:).call(drafts:)).not_to be_success

    viewer = create(:user, member_with_permissions: { project => %i[view_test_cases use_test_assistant] })
    own = create(:tm_assistant_generation, :done, project:, user: viewer)
    expect(described_class.new(user: viewer, generation: own).call(drafts: own.drafts)).not_to be_success
    expect(TestManagement::TestCase.count).to eq(0)
  end
end
