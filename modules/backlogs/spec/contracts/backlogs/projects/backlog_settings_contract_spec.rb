# frozen_string_literal: true

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe Backlogs::Projects::BacklogSettingsContract, type: :model, with_ee: %i[sprint_sharing multiple_active_sprints] do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:permissions) { %i(share_sprint) }

  subject(:contract) { described_class.new(project, current_user) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project(*permissions, project:)
      mock.allow_in_project(*other_permissions, project: other_project) if defined?(other_project)
    end
  end

  it "is expected to be a subclass of ModelContract" do
    expect(described_class).to be < ModelContract
  end

  describe "validations" do
    it_behaves_like "contract is valid"

    it { expect(subject).to validate_presence_of(:sprint_sharing) }

    it do
      expect(subject)
        .to validate_inclusion_of(:sprint_sharing).in_array(Project::SPRINT_SHARING_MODES)
    end

    # This spec of explicitly setting sprint_sharing to empty is required because the
    # simple presence validation spec is not sufficient to catch certain corner cases.
    # For example, when the sprint_sharing getter is overridden to provide a default value,
    # and the user submits an empty value, the contract should be invalid.
    context "when sprint_sharing is empty" do
      before { project.sprint_sharing = "" }

      it_behaves_like "contract is invalid", sprint_sharing: :blank
    end

    describe "permissions" do
      context "when user can share sprint" do
        let(:permissions) { %i(share_sprint) }

        it_behaves_like "contract is valid"
      end

      context "when user cannot share sprint" do
        let(:permissions) { [] }

        it_behaves_like "contract user is unauthorized"
      end
    end

    context "when the `sprint_sharing` is not part of the current EE token", with_ee: [] do
      context "when sprint sharing is set to 'no_sharing'" do
        before { project.sprint_sharing = Project::NO_SHARING }

        it_behaves_like "contract is valid"
      end

      context "when sprint sharing is set to 'share_all_projects'" do
        before { project.sprint_sharing = Project::SHARE_ALL_PROJECTS }

        it_behaves_like "contract is invalid",
                        sprint_sharing: { error: :enterprise_plan_required, plan_name: "basic enterprise plan" }
      end

      context "when sprint sharing is set to 'share_subprojects'" do
        before { project.sprint_sharing = Project::SHARE_SUBPROJECTS }

        it_behaves_like "contract is invalid",
                        sprint_sharing: { error: :enterprise_plan_required, plan_name: "basic enterprise plan" }
      end

      context "when sprint sharing is set to 'receive_shared'" do
        before { project.sprint_sharing = Project::RECEIVE_SHARED }

        it_behaves_like "contract is invalid",
                        sprint_sharing: { error: :enterprise_plan_required, plan_name: "basic enterprise plan" }
      end

      context "when sprint sharing remains on 'share_all_projects'" do
        before do
          project.sprint_sharing = Project::SHARE_ALL_PROJECTS
          project.clear_changes_information
        end

        it_behaves_like "contract is valid"
      end

      context "when sprint sharing remains on 'share_subprojects'" do
        before do
          project.sprint_sharing = Project::SHARE_SUBPROJECTS
          project.clear_changes_information
        end

        it_behaves_like "contract is valid"
      end

      context "when sprint sharing remains on 'receive_shared'" do
        before do
          project.sprint_sharing = Project::RECEIVE_SHARED
          project.clear_changes_information
        end

        it_behaves_like "contract is valid"
      end
    end

    describe "#validate_global_sprint_sharer_uniqueness" do
      before do
        project.sprint_sharing = "share_all_projects"
      end

      context "when no other project shares with all projects" do
        it_behaves_like "contract is valid"
      end

      context "when the project already has share_all_projects" do
        let(:project) { create(:project, sprint_sharing: "share_all_projects") }

        it_behaves_like "contract is valid"
      end

      context "when another project already shares with all projects" do
        let!(:other_project) { create(:project, sprint_sharing: "share_all_projects") }
        let(:other_permissions) { %i(view_project) }

        it_behaves_like "contract is invalid", sprint_sharing: :share_all_projects_already_taken

        context "when sprint_sharing is set to Share subprojects" do
          before { project.sprint_sharing = "share_subprojects" }

          it_behaves_like "contract is valid"
        end

        context "when the other project is archived" do
          let!(:other_project) { create(:project, :archived, sprint_sharing: "share_all_projects") }

          it_behaves_like "contract is valid"
        end

        context "when the current user cannot see the other project" do
          let(:other_permissions) { [] }

          it_behaves_like "contract is invalid", sprint_sharing: :share_all_projects_already_taken_anonymous
        end
      end
    end

    describe "#allow_multiple_active_sprints" do
      context "when the `multiple_active_sprints` EE feature is not available", with_ee: [] do
        context "when enabling the setting" do
          before { project.allow_multiple_active_sprints = true }

          it_behaves_like "contract is invalid",
                          allow_multiple_active_sprints: { error: :enterprise_plan_required, plan_name: "basic enterprise plan" }
        end

        context "when disabling the setting" do
          let(:project) { create(:project, allow_multiple_active_sprints: true) }

          before { project.allow_multiple_active_sprints = false }

          it_behaves_like "contract is valid"
        end

        context "when the setting is unchanged" do
          let(:project) { create(:project, allow_multiple_active_sprints: true) }

          it_behaves_like "contract is valid"
        end
      end

      context "when enabling the setting while sprint sharing is no_sharing (default)" do
        before { project.allow_multiple_active_sprints = true }

        it_behaves_like "contract is valid"
      end

      context "when enabling the setting while sprint sharing is not no_sharing" do
        before do
          project.sprint_sharing = Project::SHARE_ALL_PROJECTS
          project.allow_multiple_active_sprints = true
        end

        it_behaves_like "contract is invalid", allow_multiple_active_sprints: :requires_no_sharing
      end

      context "when sprint_sharing is changed to 'share_subprojects' while allow_multiple_active_sprints is enabled" do
        let(:project) { create(:project, allow_multiple_active_sprints: true) }

        before { project.sprint_sharing = Project::SHARE_SUBPROJECTS }

        it_behaves_like "contract is invalid", sprint_sharing: :locked_by_multiple_active_sprints
      end

      context "when sprint_sharing is changed to 'share_all_projects' while allow_multiple_active_sprints is enabled" do
        let(:project) { create(:project, allow_multiple_active_sprints: true) }

        before { project.sprint_sharing = Project::SHARE_ALL_PROJECTS }

        it_behaves_like "contract is invalid", sprint_sharing: :locked_by_multiple_active_sprints
      end

      context "when sprint_sharing is changed to 'receive_shared' while allow_multiple_active_sprints is enabled" do
        let(:project) { create(:project, allow_multiple_active_sprints: true) }

        before { project.sprint_sharing = Project::RECEIVE_SHARED }

        it_behaves_like "contract is invalid", sprint_sharing: :locked_by_multiple_active_sprints
      end

      context "when sprint_sharing is unchanged while allow_multiple_active_sprints is enabled" do
        let(:project) { create(:project, allow_multiple_active_sprints: true) }

        it_behaves_like "contract is valid"
      end

      context "when sprint_sharing is explicitly set to its current value while allow_multiple_active_sprints is enabled" do
        let(:project) { create(:project, allow_multiple_active_sprints: true, sprint_sharing: Project::NO_SHARING) }

        before { project.sprint_sharing = Project::NO_SHARING }

        it_behaves_like "contract is valid"
      end

      context "when toggling allow_multiple_active_sprints while multiple active sprints exist" do
        let(:project) { create(:project, allow_multiple_active_sprints: true) }

        before do
          create(:sprint, project:, status: "active")
          create(:sprint, project:, status: "active")
          project.allow_multiple_active_sprints = false
        end

        it_behaves_like "contract is invalid", allow_multiple_active_sprints: :locked_by_multiple_active_sprints
      end

      context "when toggling allow_multiple_active_sprints while only one active sprint exists" do
        let(:project) { create(:project, allow_multiple_active_sprints: true) }

        before do
          create(:sprint, project:, status: "active")
          project.allow_multiple_active_sprints = false
        end

        it_behaves_like "contract is valid"
      end
    end

    describe "#validate_no_active_or_borrowed_sprint_when_receiving_shared_sprints" do
      let(:project) { create(:project, sprint_sharing: Project::NO_SHARING) }

      context "when an active sprint of its own has a work package assigned" do
        let(:active_sprint) { create(:sprint, project:, status: "active") }
        let!(:work_package) { create(:work_package, project:, sprint: active_sprint) }

        before { project.sprint_sharing = Project::RECEIVE_SHARED }

        it_behaves_like "contract is invalid", sprint_sharing: :active_or_borrowed_sprint_blocks_receiving

        context "when the project allows multiple active sprints" do
          before { project.allow_multiple_active_sprints = true }

          it_behaves_like "contract is invalid", sprint_sharing: :locked_by_multiple_active_sprints
        end
      end

      context "when an active sprint of its own has no work packages assigned" do
        let!(:active_sprint) { create(:sprint, project:, status: "active") }

        before { project.sprint_sharing = Project::RECEIVE_SHARED }

        it_behaves_like "contract is valid"
      end

      context "when the project has no active sprint of its own" do
        let!(:in_planning_sprint) { create(:sprint, project:, status: "in_planning") }

        before { project.sprint_sharing = Project::RECEIVE_SHARED }

        it_behaves_like "contract is valid"
      end

      context "when a non-active sprint of its own has a work package assigned" do
        let(:in_planning_sprint) { create(:sprint, project:, status: "in_planning") }
        let!(:work_package) { create(:work_package, project:, sprint: in_planning_sprint) }

        before { project.sprint_sharing = Project::RECEIVE_SHARED }

        it_behaves_like "contract is valid"
      end

      context "when an active borrowed sprint has a work packages assigned" do
        let(:borrowed_active_sprint) do
          create(:sprint, project: create(:project, sprint_sharing: Project::NO_SHARING), status: "active")
        end
        let!(:work_package) { create(:work_package, project:, sprint: borrowed_active_sprint) }

        before { project.sprint_sharing = Project::RECEIVE_SHARED }

        it_behaves_like "contract is invalid", sprint_sharing: :active_or_borrowed_sprint_blocks_receiving
      end

      context "when a non-active borrowed sprint has a work package assigned" do
        let(:borrowed_in_planning_sprint) do
          create(:sprint, project: create(:project, sprint_sharing: Project::NO_SHARING), status: "in_planning")
        end
        let!(:work_package) { create(:work_package, project:, sprint: borrowed_in_planning_sprint) }

        before { project.sprint_sharing = Project::RECEIVE_SHARED }

        it_behaves_like "contract is invalid", sprint_sharing: :active_or_borrowed_sprint_blocks_receiving
      end

      context "when a borrowed sprint from the sharer has a work package assigned" do
        let(:sharer) { create(:project, sprint_sharing: Project::SHARE_SUBPROJECTS) }
        let(:borrowed_active_sprint) { create(:sprint, project: sharer, status: "active") }
        let!(:work_package) { create(:work_package, project:, sprint: borrowed_active_sprint) }

        before { project.sprint_sharing = Project::RECEIVE_SHARED }

        it_behaves_like "contract is invalid", sprint_sharing: :active_or_borrowed_sprint_blocks_receiving
      end

      context "when no work packages are linked to any foreign sprint" do
        before { project.sprint_sharing = Project::RECEIVE_SHARED }

        it_behaves_like "contract is valid"
      end

      context "when sprint_sharing is unchanged" do
        let(:active_sprint) { create(:sprint, project:, status: "active") }

        before do
          create(:work_package, project:, sprint: active_sprint)
          project.update!(sprint_sharing: Project::RECEIVE_SHARED)
        end

        it_behaves_like "contract is valid"
      end
    end

    describe "#validate_no_work_packages_in_shared_sprints_when_leaving_receiving" do
      let(:sharer) { nil }
      let(:sprint_sharing) { Project::RECEIVE_SHARED }
      let(:project) { create(:project, parent: sharer, sprint_sharing:) }

      context "when the sharer has a sprint" do
        let(:sharer) { create(:project, sprint_sharing: Project::SHARE_SUBPROJECTS) }
        let!(:sharer_sprint) { create(:sprint, project: sharer, status: "in_planning") }

        before { project.sprint_sharing = Project::NO_SHARING }

        it_behaves_like "contract is valid"

        context "when the project allows multiple active sprints" do
          before { project.allow_multiple_active_sprints = true }

          it_behaves_like "contract is invalid", sprint_sharing: :locked_by_multiple_active_sprints
        end

        context "and a work package is assigned to it" do
          let!(:work_package) { create(:work_package, project:, sprint: sharer_sprint) }

          it_behaves_like "contract is invalid", sprint_sharing: :work_packages_still_linked_to_shared_sprints

          context "when the sharer's sprint is active" do
            let(:sharer_sprint) { create(:sprint, project: sharer, status: "active") }

            it_behaves_like "contract is invalid", sprint_sharing: :work_packages_still_linked_to_shared_sprints
          end
        end
      end

      context "when a work package is linked to a native sprint of its own" do
        let(:own_sprint) { create(:sprint, project:) }
        let!(:work_package) { create(:work_package, project:, sprint: own_sprint) }

        before { project.sprint_sharing = Project::NO_SHARING }

        it_behaves_like "contract is valid"
      end

      context "when no work packages are linked to any foreign sprint" do
        before { project.sprint_sharing = Project::NO_SHARING }

        it_behaves_like "contract is valid"
      end

      context "when sprint_sharing stays receive_shared" do
        let(:sharer) { create(:project, sprint_sharing: Project::SHARE_SUBPROJECTS) }
        let(:sharer_sprint) { create(:sprint, project: sharer, status: "active") }
        let!(:work_package) { create(:work_package, project:, sprint: sharer_sprint) }

        it_behaves_like "contract is valid"
      end

      context "when switching between two non-receiving modes" do
        let(:sprint_sharing) { Project::NO_SHARING }

        before { project.sprint_sharing = Project::SHARE_SUBPROJECTS }

        it_behaves_like "contract is valid"
      end
    end
  end

  describe "#writable_attributes" do
    it "allows sprint_sharing and allow_multiple_active_sprints to be written" do
      expect(contract.writable_attributes).to include("sprint_sharing", "allow_multiple_active_sprints")
      expect(contract.writable_attributes).not_to include("settings")
      expect(contract.writable_attributes).not_to include("deactivate_work_package_attachments")
    end

    context "when sprint_sharing is the only changed setting" do
      before { project.sprint_sharing = "share_subprojects" }

      it "includes the settings column too" do
        expect(contract.writable_attributes).to include("settings")
      end

      it_behaves_like "contract is valid"
    end

    context "when allow_multiple_active_sprints is the only changed setting" do
      before { project.allow_multiple_active_sprints = true }

      it "includes the settings column too" do
        expect(contract.writable_attributes).to include("settings")
      end
    end

    context "when other settings keys are also changed" do
      before do
        project.sprint_sharing = "share_subprojects"
        project.deactivate_work_package_attachments = true
      end

      it "excludes the settings column" do
        expect(contract.writable_attributes).not_to include("settings")
      end

      it_behaves_like "contract is invalid", settings: :error_readonly
    end
  end
end
