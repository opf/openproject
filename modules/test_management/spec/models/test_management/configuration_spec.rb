# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Configuration do
  shared_let(:project) { create(:project) }

  let!(:browsers) { create(:tm_configuration_group, project:, name: "Browsers") }
  let!(:oses) { create(:tm_configuration_group, project:, name: "OS") }
  let!(:chrome) { create(:tm_configuration, configuration_group: browsers, name: "Chrome") }
  let!(:firefox) { create(:tm_configuration, configuration_group: browsers, name: "Firefox") }
  let!(:windows) { create(:tm_configuration, configuration_group: oses, name: "Windows") }
  let!(:linux) { create(:tm_configuration, configuration_group: oses, name: "Linux") }

  describe ".combinations_for" do
    it "returns one empty combination when no ids are given" do
      expect(described_class.combinations_for([])).to eq([[]])
    end

    it "returns one combination per config when a single group is selected" do
      combos = described_class.combinations_for([chrome.id, firefox.id])
      expect(combos.map { |c| c.map(&:name) }).to contain_exactly(%w[Chrome], %w[Firefox])
    end

    it "returns the cartesian product across groups" do
      combos = described_class.combinations_for([chrome.id, firefox.id, windows.id, linux.id])
      expect(combos.map { |c| c.map(&:name) }).to contain_exactly(
        %w[Chrome Windows], %w[Chrome Linux], %w[Firefox Windows], %w[Firefox Linux]
      )
    end
  end

  describe ".label_for" do
    it "joins the first combination's names" do
      expect(described_class.label_for([chrome.id, windows.id])).to eq("Chrome, Windows")
    end

    it "returns nil for an empty selection" do
      expect(described_class.label_for([])).to be_nil
    end
  end
end
