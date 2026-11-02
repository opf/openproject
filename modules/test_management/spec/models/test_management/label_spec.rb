# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Label do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }

  it "derives a stable color from the name when none is given" do
    label = described_class.create!(project:, name: "smoke")

    expect(described_class::COLORS).to include(label.color)
    expect(label.color).to eq(described_class.color_for("smoke"))
    expect(described_class.color_for("SMOKE")).to eq(described_class.color_for("smoke"))
  end

  it "keeps an explicit color" do
    color = described_class::COLORS.last
    expect(described_class.create!(project:, name: "x", color:).color).to eq(color)
  end

  it "rejects unknown colors" do
    expect(described_class.new(project:, name: "x", color: "rainbow")).not_to be_valid
  end

  it "requires a name of at most 64 characters" do
    expect(described_class.new(project:, name: "")).not_to be_valid
    expect(described_class.new(project:, name: "a" * 65)).not_to be_valid
  end

  it "is unique per project, case-insensitively" do
    described_class.create!(project:, name: "Regression")
    other = create(:project)

    expect(described_class.new(project:, name: "regression")).not_to be_valid
    expect(described_class.new(project: other, name: "regression")).to be_valid
  end

  it "normalizes names" do
    expect(described_class.normalize_name("  smoke   test ")).to eq("smoke test")
    expect(described_class.normalize_name("a" * 100).length).to eq(64)
  end

  it "orders case-insensitively" do
    b = described_class.create!(project:, name: "beta")
    a = described_class.create!(project:, name: "Alpha")

    expect(described_class.where(project:).ordered).to eq([a, b])
  end

  it "gets a color when autosaved through a test case (validation skipped)" do
    test_case = create(:tm_test_case, project:)
    test_case.test_case_labels.build(label: described_class.new(project:, name: "autosaved"))
    test_case.save!

    expect(described_class.find_by(name: "autosaved").color).to be_present
  end
end
