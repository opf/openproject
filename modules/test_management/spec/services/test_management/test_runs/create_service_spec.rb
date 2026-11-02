# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestRuns::CreateService do
  let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  let(:user) do
    create(:user, member_with_permissions: { project => %i[view_test_runs add_test_runs view_test_cases view_work_packages] })
  end
  let(:root) { create(:tm_suite, project:) }
  let(:sub) { create(:tm_suite, project:, parent: root) }
  let!(:in_root) { create(:tm_test_case, project:, suite: root) }
  let!(:in_sub) { create(:tm_test_case, project:, suite: sub, automated: true) }
  let!(:unfiled) { create(:tm_test_case, project:) }

  def create_run(params)
    described_class.new(user:).call(params.merge(project:))
  end

  it "creates a new run with the author and references" do
    wp = create(:work_package, project:)
    result = create_run(name: "Release check", work_package_ids: ["", wp.id.to_s], start_date: "2026-11-01")

    expect(result).to be_success
    run = result.result
    expect(run).to have_attributes(state: "new", author: user, selection_mode: "specific", start_date: Date.new(2026, 11, 1))
    expect(run.work_packages).to eq([wp])
  end

  it "adds selected cases and every case of selected folders (incl. subfolders)" do
    result = create_run(name: "Specific", selection_mode: "specific",
                        selection_suite_ids: [root.id.to_s], test_case_ids: [unfiled.id.to_s])

    expect(result.result.test_cases).to contain_exactly(in_root, in_sub, unfiled)
  end

  it "adds every case in all mode, assigned to the run assignee" do
    result = create_run(name: "All", selection_mode: "all", assigned_to_id: user.id)

    expect(result.result.run_cases.map(&:test_case)).to contain_exactly(in_root, in_sub, unfiled)
    expect(result.result.run_cases.map(&:assigned_to)).to all(eq(user))
    expect(result.result.run_cases.map(&:status)).to all(eq("untested"))
  end

  it "adds matching cases in dynamic mode" do
    result = create_run(name: "Automated", selection_mode: "dynamic", filter_options: { automation: "automated" })

    expect(result.result.test_cases).to contain_exactly(in_sub)
    expect(result.result.filter_options).to eq("label_ids" => [], "suite_ids" => [], "automation" => "automated")
  end

  it "fails without a name" do
    result = create_run(name: "")

    expect(result).not_to be_success
    expect(TestManagement::TestRun.count).to eq(0)
  end

  it "fails without permission" do
    viewer = create(:user, member_with_permissions: { project => %i[view_test_runs] })
    result = described_class.new(user: viewer).call(name: "Nope", project:)

    expect(result).not_to be_success
  end
end
