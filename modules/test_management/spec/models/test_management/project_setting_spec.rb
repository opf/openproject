# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::ProjectSetting do
  let(:project) { create(:project) }

  it "defaults folder tree layout to split_pane" do
    setting = described_class.for_project(project)
    expect(setting.effective_folder_tree_layout).to eq("split_pane")
    expect(setting.split_pane_layout?).to be(true)
  end

  it "persists sidebar layout" do
    setting = described_class.for_project(project)
    setting.folder_tree_layout = "sidebar"
    setting.save!

    reloaded = described_class.find(setting.id)
    expect(reloaded.effective_folder_tree_layout).to eq("sidebar")
    expect(reloaded.sidebar_layout?).to be(true)
    expect(described_class.folder_tree_layout_for(project)).to eq("sidebar")
  end

  it "rejects unknown layouts" do
    setting = described_class.for_project(project)
    setting.folder_tree_layout = "floating"
    expect(setting).not_to be_valid
    expect(setting.errors[:folder_tree_layout]).to be_present
  end

  describe "milestones switch" do
    it "is on by default and can be switched off" do
      expect(described_class.milestones_enabled?(project)).to be(true)

      setting = described_class.for_project(project)
      setting.enable_milestones = false
      setting.save!

      expect(described_class.milestones_enabled?(project)).to be(false)
      expect(described_class.milestones_disabled_project_ids).to eq([project.id])
      expect(TestManagement::Milestone.enabled_for?(project)).to be(false)
    end
  end
end
