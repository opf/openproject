# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Plans::Runs::SpawnFromEntryService do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases view_test_runs add_test_runs view_test_plans manage_test_plans]
           })
  end

  let(:plan) { create(:tm_test_plan, project:, author: user) }
  let(:browsers) { create(:tm_configuration_group, project:, name: "Browsers") }
  let(:oses) { create(:tm_configuration_group, project:, name: "OS") }
  let!(:chrome) { create(:tm_configuration, configuration_group: browsers, name: "Chrome") }
  let!(:firefox) { create(:tm_configuration, configuration_group: browsers, name: "Firefox") }
  let!(:windows) { create(:tm_configuration, configuration_group: oses, name: "Windows") }
  let!(:linux) { create(:tm_configuration, configuration_group: oses, name: "Linux") }

  it "creates four runs for a 2×2 configuration matrix" do
    entry = create(:tm_test_plan_entry, test_plan: plan, name: "Browser suite", selection_mode: "all",
                                        configuration_ids: [chrome.id, firefox.id, windows.id, linux.id])

    result = described_class.new(user:, entry:).call

    expect(result).to be_success
    runs = entry.test_runs.reload
    expect(runs.size).to eq(4)
    expect(runs.map(&:configuration_label)).to contain_exactly(
      "Chrome, Windows", "Chrome, Linux", "Firefox, Windows", "Firefox, Linux"
    )
    expect(runs.map(&:test_plan_id).uniq).to eq([plan.id])
  end

  it "creates a single run when no configurations are selected" do
    entry = create(:tm_test_plan_entry, test_plan: plan, name: "Smoke", selection_mode: "all",
                                        configuration_ids: [])

    expect(described_class.new(user:, entry:).call).to be_success
    expect(entry.test_runs.reload.size).to eq(1)
    expect(entry.test_runs.first.configuration_label).to be_nil
  end
end
