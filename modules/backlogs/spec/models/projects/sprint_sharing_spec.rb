# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::SprintSharing do
  let(:sprint_sharing) { "no_sharing" }
  let(:active) { true }
  let!(:project) { create(:project, sprint_sharing:, active:) }

  describe "SPRINT_SHARING_MODES" do
    it "defines all supported sprint sharing options" do
      expect(described_class::SPRINT_SHARING_MODES).to match_array(
        %w[share_all_projects share_subprojects no_sharing receive_shared]
      )
    end

    it "is exposed on Project" do
      expect(Project::SPRINT_SHARING_MODES).to eq(described_class::SPRINT_SHARING_MODES)
    end
  end

  describe "#sprint_sharing" do
    let(:sprint_sharing) { nil }

    it "defaults to no_sharing" do
      expect(project.sprint_sharing).to eq("no_sharing")
    end

    it "persists configured values" do
      project.update!(sprint_sharing: "share_subprojects")

      expect(project.reload.sprint_sharing).to eq("share_subprojects")
    end
  end

  describe "predicate methods" do
    it "#share_sprints_with_all_projects? returns true when sharing with all projects" do
      project.sprint_sharing = "share_all_projects"
      expect(project).to be_share_sprints_with_all_projects
    end

    it "#share_sprints_with_subprojects? returns true when sharing with subprojects" do
      project.sprint_sharing = "share_subprojects"
      expect(project).to be_share_sprints_with_subprojects
    end

    it "#receive_shared_sprints? returns true when receiving shared sprints" do
      project.sprint_sharing = "receive_shared"
      expect(project).to be_receive_shared_sprints
    end

    it "#not_sharing_sprints? returns true when not sharing (default)" do
      expect(project).to be_not_sharing_sprints
    end

    it "predicates return false for non-matching values" do
      project.sprint_sharing = "share_subprojects"

      expect(project).not_to be_share_sprints_with_all_projects
      expect(project).not_to be_receive_shared_sprints
      expect(project).not_to be_not_sharing_sprints
    end
  end

  describe "#not_sharing_sprints!" do
    context "when the project is already set to no_sharing" do
      let(:sprint_sharing) { "no_sharing" }

      it "does not update the database" do
        allow(project).to receive(:update_column)

        subject

        expect(project).not_to have_received(:update_column)
      end
    end

    context "when the project has an active sharing mode" do
      let(:sprint_sharing) { "share_all_projects" }

      it "resets sprint_sharing to no_sharing" do
        project.not_sharing_sprints!

        expect(project.reload.sprint_sharing).to eq("no_sharing")
      end
    end
  end

  describe ".global_sprint_sharer" do
    context "when no project shares with all projects" do
      let(:sprint_sharing) { "no_sharing" }

      it "returns nil" do
        expect(Project.global_sprint_sharer).to be_nil
      end
    end

    context "when a project shares with all projects" do
      let(:sprint_sharing) { "share_all_projects" }

      it "returns that project" do
        expect(Project.global_sprint_sharer).to eq(project)
      end
    end

    context "when the sharing project is archived" do
      let(:sprint_sharing) { "share_all_projects" }
      let(:active) { false }

      it "returns nil" do
        expect(Project.global_sprint_sharer).to be_nil
      end
    end
  end

  describe "#sprint_source" do
    let(:global_sprint_sharing) { "share_all_projects" }
    let(:root_sprint_sharing) { "share_subprojects" }
    let(:parent_sprint_sharing) { "share_subprojects" }
    let(:project_sprint_sharing) { "receive_shared" }

    let!(:global_sharer) { create(:project, sprint_sharing: global_sprint_sharing) }
    let!(:root_project) { create(:project, sprint_sharing: root_sprint_sharing) }
    let!(:parent_project) { create(:project, parent: root_project, sprint_sharing: parent_sprint_sharing) }
    let!(:project) { create(:project, parent: parent_project, sprint_sharing: project_sprint_sharing) }

    # Projects that should not be returned
    shared_let(:other_project) { create(:project, sprint_sharing: "share_subprojects") }
    shared_let(:archived_global_sharer) { create(:project, :archived, sprint_sharing: "share_all_projects") }

    shared_examples "returns the project itself" do
      it "returns only itself" do
        expect(project.sprint_source).to contain_exactly(project)
      end
    end

    shared_examples "executes a single SQL query" do
      it "resolves sprint_source in a single query" do
        expect { project.sprint_source.load }.to have_a_query_limit(1)
      end
    end

    context "when sprint_sharing is no_sharing (default)" do
      let(:project_sprint_sharing) { "no_sharing" }

      it_behaves_like "returns the project itself"
      it_behaves_like "executes a single SQL query"
    end

    context "when sprint_sharing is share_subprojects" do
      let(:project_sprint_sharing) { "share_subprojects" }

      it_behaves_like "returns the project itself"
      it_behaves_like "executes a single SQL query"
    end

    context "when sprint_sharing is share_all_projects" do
      let(:global_sprint_sharing) { "no_sharing" }
      let(:root_sprint_sharing) { "share_subprojects" }
      let(:parent_sprint_sharing) { "share_subprojects" }
      let(:project_sprint_sharing) { "share_all_projects" }

      it_behaves_like "returns the project itself"
      it_behaves_like "executes a single SQL query"
    end

    context "when sprint_sharing is receive_shared" do
      let(:project_sprint_sharing) { "receive_shared" }

      context "with only a global sharer" do
        let(:global_sprint_sharing) { "share_all_projects" }
        let(:root_sprint_sharing) { "no_sharing" }
        let(:parent_sprint_sharing) { "no_sharing" }

        it "returns only the global sharer" do
          expect(project.sprint_source).to contain_exactly(global_sharer)
        end

        it_behaves_like "executes a single SQL query"
      end

      context "with a global sharer and both ancestors sharing subprojects" do
        let(:global_sprint_sharing) { "share_all_projects" }
        let(:root_sprint_sharing) { "share_subprojects" }
        let(:parent_sprint_sharing) { "share_subprojects" }

        it "returns only the closest sharing ancestor" do
          expect(project.sprint_source).to contain_exactly(parent_project)
        end

        it_behaves_like "executes a single SQL query"
      end

      context "with no sharing sources" do
        let(:global_sprint_sharing) { "no_sharing" }
        let(:root_sprint_sharing) { "no_sharing" }
        let(:parent_sprint_sharing) { "no_sharing" }

        it "returns an empty scope" do
          expect(project.sprint_source).to be_empty
        end

        it_behaves_like "executes a single SQL query"
      end
    end
  end
end
