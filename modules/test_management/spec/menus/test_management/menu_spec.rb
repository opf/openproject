# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Menu do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }

  let(:permissions) { %i[view_test_cases view_test_runs view_test_plans use_test_assistant] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:section) { "runs" }
  let(:menu) { described_class.new(project:, params: ActionController::Parameters.new(section:), user:) }
  let(:items) { menu.menu_items.first.children }

  describe ".section_for" do
    it "maps the module controllers to their section" do
      expect(described_class.section_for("test_management/test_cases")).to eq("cases")
      expect(described_class.section_for("test_management/suites")).to eq("cases")
      expect(described_class.section_for("test_management/test_runs")).to eq("runs")
      expect(described_class.section_for("test_management/test_run_cases")).to eq("runs")
      expect(described_class.section_for("test_management/ci_triggers")).to eq("runs")
      expect(described_class.section_for("test_management/milestones")).to eq("milestones")
      expect(described_class.section_for("test_management/assistant")).to eq("assistant")
    end

    it "uses the page of a placeholder and ignores unknown pages and controllers" do
      expect(described_class.section_for("test_management/placeholders", "ci")).to eq("ci")
      expect(described_class.section_for("test_management/placeholders", "reports")).to be_nil
      expect(described_class.section_for("test_management/placeholders", "nope")).to be_nil
      expect(described_class.section_for("work_packages")).to be_nil
    end
  end

  it "lists the sections in module order and highlights the current one" do
    expect(items.map(&:title)).to eq(["Cases", "Test Assistant", "Runs", "Plans", "Milestones"])
    expect(items.select(&:selected).map(&:title)).to eq(["Runs"])
    expect(items.find { it.title == "Runs" }.href).to eq("/projects/#{project.identifier}/test_management/test_runs")
  end

  context "with an unknown section" do
    let(:section) { "<script>" }

    it "highlights nothing" do
      expect(menu.current_section).to be_nil
      expect(items.none?(&:selected)).to be(true)
    end
  end

  context "without the run and assistant permissions" do
    let(:permissions) { %i[view_test_cases] }

    it "hides Runs, Milestones and the Test Assistant" do
      expect(items.map(&:title)).to eq(%w[Cases])
    end
  end

  context "with the Test Assistant and Milestones switched off for the project" do
    before { create(:tm_project_setting, project:, enable_test_assistant: false, enable_milestones: false) }

    it "hides both entries" do
      expect(items.map(&:title)).to eq(%w[Cases Runs Plans])
    end
  end

  context "with the module disabled" do
    let(:project) { create(:project, enabled_module_names: %i[work_package_tracking]) }

    it "lists nothing" do
      expect(menu.visible_sections).to be_empty
    end
  end
end
