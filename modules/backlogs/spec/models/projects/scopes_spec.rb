# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::Scopes, "scopes" do
  shared_let(:project_without_settings) { create(:project, sprint_sharing: nil) }
  shared_let(:project_with_empty_settings) { create(:project, sprint_sharing: "") }
  shared_let(:no_sharing_project) { create(:project, sprint_sharing: "no_sharing") }
  shared_let(:all_projects_sharer) { create(:project, sprint_sharing: "share_all_projects") }
  shared_let(:subprojects_sharer) { create(:project, sprint_sharing: "share_subprojects") }
  shared_let(:receiver) { create(:project, sprint_sharing: "receive_shared") }

  describe ".share_sprints_with_all_projects" do
    it "returns projects that share with all projects" do
      expect(Project.share_sprints_with_all_projects).to contain_exactly(all_projects_sharer)
    end
  end

  describe ".share_sprints_with_subprojects" do
    it "returns projects that share with subprojects" do
      expect(Project.share_sprints_with_subprojects).to contain_exactly(subprojects_sharer)
    end
  end

  describe ".receive_shared_sprints" do
    it "returns projects that receive shared sprints" do
      expect(Project.receive_shared_sprints).to contain_exactly(receiver)
    end
  end

  describe ".not_sharing_sprints" do
    it "returns projects with no sharing" do
      expect(Project.not_sharing_sprints).to contain_exactly(
        project_without_settings,
        project_with_empty_settings,
        no_sharing_project
      )
    end
  end
end
