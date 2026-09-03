# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Import::JiraRevertImportJob do
  subject(:job) { described_class.new(jira_import.id) }

  let(:jira) { create(:jira) }
  let(:author) { create(:admin) }
  let(:jira_import) { create(:jira_import, jira:, author:) }

  before do
    job.instance_variable_set(:@jira_import, jira_import)
    job.instance_variable_set(:@user, author)
  end

  def reference_for(entity, entity_class, uses_existing: false, import: jira_import)
    create(:jira_open_project_reference,
           jira_import: import,
           op_entity_class: entity_class,
           op_entity_id: entity.id.to_s,
           uses_existing:)
  end

  # The state machine only allows :reverted and :revert_error while reverting
  def transition_to_reverting
    allow(Import::JiraImportStateMachine).to receive(:enqueued_job_id).and_return("stubbed-job-id")
    login_as(author)

    %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching
       projects_meta_done importing imported reverting].each do |state|
      jira_import.transition_to!(state)
    end
  end

  describe "#delete_projects" do
    let(:project) { create(:project) }
    let!(:reference) { reference_for(project, "Project") }

    it "deletes the referenced project" do
      expect { job.send(:delete_projects) }.to change(Project, :count).by(-1)
      expect(Project).not_to exist(project.id)
    end

    context "when the project is already gone" do
      let(:other_project) { create(:project) }
      let!(:other_reference) { reference_for(other_project, "Project") }

      before { project.destroy }

      it "skips the dangling reference and keeps deleting the remaining ones" do
        expect { job.send(:delete_projects) }.not_to raise_error
        expect(Project).not_to exist(other_project.id)
      end
    end

    context "when the delete service fails with a message mentioning 'not found!'" do
      before do
        service = instance_double(Projects::DeleteService,
                                  call: ServiceResult.failure(message: "Parent project not found!"))
        allow(Projects::DeleteService).to receive(:new).and_return(service)
      end

      it "raises instead of mistaking the failure for a dangling reference" do
        expect { job.send(:delete_projects) }.to raise_error(RuntimeError, /Parent project not found!/)
      end
    end

    context "when the project existed before the import" do
      let(:pre_existing_project) { create(:project) }
      let!(:pre_existing_reference) { reference_for(pre_existing_project, "Project", uses_existing: true) }

      it "keeps it" do
        job.send(:delete_projects)

        expect(Project).to exist(pre_existing_project.id)
      end
    end

    context "when another import references a project" do
      let(:other_import) { create(:jira_import, jira:, author:) }
      let(:other_project) { create(:project) }
      let!(:other_reference) { reference_for(other_project, "Project", import: other_import) }

      it "leaves it alone" do
        job.send(:delete_projects)

        expect(Project).to exist(other_project.id)
      end
    end
  end

  describe "#delete_types_statuses_and_issue_priorities" do
    let!(:type) { create(:type) }
    let!(:status) { create(:status) }
    let!(:priority) { create(:priority) }

    before do
      reference_for(type, "Type")
      reference_for(status, "Status")
      reference_for(priority, "IssuePriority")
    end

    it "deletes all three kinds of entity" do
      job.send(:delete_types_statuses_and_issue_priorities)

      expect(Type).not_to exist(type.id)
      expect(Status).not_to exist(status.id)
      expect(IssuePriority).not_to exist(priority.id)
    end

    context "when a status is already gone" do
      before { status.destroy }

      it "skips the dangling reference and keeps deleting the remaining ones" do
        expect { job.send(:delete_types_statuses_and_issue_priorities) }.not_to raise_error
        expect(Type).not_to exist(type.id)
      end
    end

    context "when a type existed before the import" do
      let!(:pre_existing_type) { create(:type) }

      before { reference_for(pre_existing_type, "Type", uses_existing: true) }

      it "keeps it" do
        job.send(:delete_types_statuses_and_issue_priorities)

        expect(Type).to exist(pre_existing_type.id)
      end
    end
  end

  describe "#delete_users" do
    let(:user) { create(:user) }
    let!(:reference) { reference_for(user, "User") }

    it "marks the user as deleted and hands the deletion over to a background job" do
      expect { job.send(:delete_users) }.to enqueue_job(Principals::DeleteJob)
      expect(user.reload).to be_deleted
    end

    it "deletes the user regardless of Setting.users_deletable_by_admins" do
      allow(Setting).to receive(:users_deletable_by_admins?).and_return(false)

      expect { job.send(:delete_users) }.to enqueue_job(Principals::DeleteJob)
    end

    context "when the user is already gone" do
      before { user.destroy }

      it "skips the dangling reference" do
        expect { job.send(:delete_users) }.not_to raise_error
      end
    end

    context "when the user existed before the import" do
      let(:pre_existing_user) { create(:user) }

      before { reference_for(pre_existing_user, "User", uses_existing: true) }

      it "keeps it" do
        job.send(:delete_users)

        expect(pre_existing_user.reload).to be_active
      end
    end
  end

  describe "#delete_groups" do
    let(:group) { create(:group) }
    let!(:reference) { reference_for(group, "Group") }

    it "marks the group as deleted and hands the deletion over to a background job" do
      expect { job.send(:delete_groups) }.to enqueue_job(Principals::DeleteJob)
      expect(group.reload).to be_deleted
    end

    context "when the group is already gone" do
      before { group.destroy }

      it "skips the dangling reference" do
        expect { job.send(:delete_groups) }.not_to raise_error
      end
    end
  end

  describe "#delete_project_roles" do
    let(:project_role) { create(:project_role) }
    let!(:reference) { reference_for(project_role, "ProjectRole") }

    it "deletes the referenced role" do
      expect { job.send(:delete_project_roles) }.to change(ProjectRole, :count).by(-1)
    end

    context "when the role is already gone" do
      before { project_role.destroy }

      it "skips the dangling reference" do
        expect { job.send(:delete_project_roles) }.not_to raise_error
      end
    end
  end

  describe "#delete_custom_fields" do
    let(:custom_field) { create(:work_package_custom_field) }
    let!(:reference) { reference_for(custom_field, "WorkPackageCustomField") }

    it "deletes the referenced custom field" do
      expect { job.send(:delete_custom_fields) }.to change(WorkPackageCustomField, :count).by(-1)
    end

    context "when the custom field is already gone" do
      before { custom_field.destroy }

      it "skips the dangling reference" do
        expect { job.send(:delete_custom_fields) }.not_to raise_error
      end
    end

    context "when the custom field existed before the import" do
      let(:pre_existing_custom_field) { create(:work_package_custom_field) }

      before { reference_for(pre_existing_custom_field, "WorkPackageCustomField", uses_existing: true) }

      it "keeps it" do
        job.send(:delete_custom_fields)

        expect(WorkPackageCustomField).to exist(pre_existing_custom_field.id)
      end
    end
  end

  describe "#delete_references" do
    let(:other_import) { create(:jira_import, jira:, author:) }

    before do
      reference_for(create(:project), "Project")
      reference_for(create(:user), "User", uses_existing: true)
      reference_for(create(:project), "Project", import: other_import)
    end

    it "deletes all references of the import, including the ones for pre-existing entities" do
      job.send(:delete_references)

      expect(Import::JiraOpenProjectReference.where(jira_import_id: jira_import.id)).to be_empty
    end

    it "keeps the references of other imports" do
      job.send(:delete_references)

      expect(Import::JiraOpenProjectReference.where(jira_import_id: other_import.id).count).to eq(1)
    end
  end

  describe "#delete_jira_objects" do
    let!(:jira_user) { create(:jira_user, jira_import:) }

    before { transition_to_reverting }

    it "destroys the imported jira objects" do
      expect { job.send(:delete_jira_objects) }.to change(Import::JiraUser, :count).by(-1)
    end

    it "completes the revert" do
      job.send(:delete_jira_objects)

      expect(jira_import.reload.current_state).to eq("reverted")
    end
  end

  describe "#each_iteration" do
    before { transition_to_reverting }

    it "records the completed step as the job cursor" do
      job.each_iteration(:delete_references, jira_import.id)

      expect(jira_import.get_job_cursor(job)).to eq("delete_references")
    end

    context "when a step fails" do
      let!(:reference) { reference_for(create(:project), "Project") }

      before do
        service = instance_double(Projects::DeleteService,
                                  call: ServiceResult.failure(message: "Something went wrong"))
        allow(Projects::DeleteService).to receive(:new).and_return(service)
      end

      it "transitions the import to revert_error, recording the failing step" do
        catch(:abort) { job.each_iteration(:delete_projects, jira_import.id) }

        expect(jira_import.reload.current_state).to eq("revert_error")
        expect(jira_import.last_transition.metadata)
          .to include("error" => "Something went wrong", "revert_step" => "delete_projects")
      end

      it "aborts the iteration" do
        aborted = catch(:abort) do
          job.each_iteration(:delete_projects, jira_import.id)
          :not_aborted
        end

        expect(aborted).not_to eq(:not_aborted)
      end

      it "does not record a job cursor" do
        catch(:abort) { job.each_iteration(:delete_projects, jira_import.id) }

        expect(jira_import.get_job_cursor(job)).to be_nil
      end
    end
  end

  describe "#percentage" do
    it "is 0 while no step has been completed" do
      expect(job.percentage).to eq(0)
    end

    it "grows with every completed step" do
      jira_import.set_job_cursor(job, :delete_projects)
      expect(job.percentage).to eq(12)

      jira_import.set_job_cursor(job, :delete_jira_objects)
      expect(job.percentage).to eq(100)
    end
  end

  describe "#build_enumerator" do
    it "starts at the first step for a fresh revert" do
      enumerator = job.build_enumerator(jira_import.id, cursor: nil)

      expect(enumerator.next).to eq([:delete_projects, 0])
    end

    it "resumes after the last completed step" do
      jira_import.set_job_cursor(job, :delete_projects)

      enumerator = job.build_enumerator(jira_import.id, cursor: nil)

      expect(enumerator.next).to eq([:delete_types_statuses_and_issue_priorities, 1])
    end
  end
end
