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

RSpec.describe Projects::CreationWizard::CreateArtifactWorkPackageService do
  shared_let(:status_new) { create(:status, name: "New") }
  shared_let(:type) { create(:type, name: "Project initiation") }
  shared_let(:user_custom_field) { create(:user_project_custom_field, name: "Project Manager") }
  shared_let(:assignee_user) { create(:user, firstname: "assignee_user") }
  shared_let(:current_user) { create(:user, lastname: "current_user") }
  shared_let(:role) do
    create(:project_role, permissions: %i[
             add_work_packages
             view_project_attributes
             work_package_assigned
           ])
  end
  shared_let(:default_priority) { create(:default_priority) }
  shared_let(:project) do
    create(
      :project,
      name: "Important Project",
      types: [type],
      project_custom_fields: [user_custom_field],
      # project initiation request settings
      project_creation_wizard_artifact_name: "project_mandate",
      project_creation_wizard_enabled: true,
      project_creation_wizard_work_package_type_id: type.id,
      project_creation_wizard_status_when_submitted_id: status_new.id,
      project_creation_wizard_assignee_custom_field_id: user_custom_field.id,
      project_creation_wizard_work_package_comment: "PIR submitted for **Project Name**.",
      user_custom_field.attribute_name => assignee_user.id
    ).tap do |p|
      p.members << create(:member, principal: assignee_user, project: p, roles: [role])
      p.members << create(:member, principal: current_user, project: p, roles: [role])
    end
  end

  let(:mocked_contract) { instance_double(Projects::CreateArtifactWorkPackageContract, "mocked_contract") }
  let(:instance) do
    described_class.new(user: current_user, model: project).tap do |instance|
      allow(instance).to receive(:instantiate_contract).and_return(mocked_contract)
    end
  end

  before do
    login_as current_user
  end

  context "when contract is valid" do
    before do
      allow(mocked_contract).to receive(:validate).and_return(true)
    end

    it "creates an artifact work package (for after submitting a project initiation request)" do
      result = instance.call

      expect(result.errors.full_messages).to be_empty
      project = result.result
      expect(project.project_creation_wizard_artifact_work_package_id).to be_present
    end

    it "uses the type and status defined in the project initiation request settings" do
      result = instance.call
      project = result.result
      artifact_work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
      expect(artifact_work_package.type.id).to eq(project.project_creation_wizard_work_package_type_id)
      expect(artifact_work_package.status.id).to eq(project.project_creation_wizard_status_when_submitted_id)
    end

    it "assigns the artifact work package to the user pointed by the 'Assignee when submitted' custom field" do
      result = instance.call
      project = result.result

      artifact_work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
      expect(artifact_work_package.assigned_to).to eq(assignee_user)
    end

    it "sets the subject to the artifact name configured in the project initiation request settings" do
      result = instance.call
      project = result.result

      artifact_work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
      expected_name = I18n.t("settings.project_initiation_request.name.options.#{project.project_creation_wizard_artifact_name}")
      expect(artifact_work_package.subject).to eq(expected_name)
    end

    it "if the artifact name is misconfigured (unexisting name key), " \
         "sets the subject to the 'project_creation_wizard' artifact name" do
      project.update(project_creation_wizard_artifact_name: "misconfigured")
      result = instance.call
      project = result.result

      artifact_work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
      expected_name = I18n.t("settings.project_initiation_request.name.options.project_creation_wizard")
      expect(artifact_work_package.subject).to eq(expected_name)
    end

    it "if the artifact name is nil, sets the subject to the 'project_creation_wizard' artifact name" do
      project.update(project_creation_wizard_artifact_name: nil)
      result = instance.call
      project = result.result

      artifact_work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
      expected_name = I18n.t("settings.project_initiation_request.name.options.project_creation_wizard")
      expect(artifact_work_package.subject).to eq(expected_name)
    end

    it "adds a comment to the artifact work package " \
         "using the project_creation_wizard_work_package_comment setting " \
         "and mentioning the assignee" do
      result = instance.call
      project = result.result

      artifact_work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
      expect(artifact_work_package.last_journal.notes).not_to be_empty
      expect(artifact_work_package.last_journal.notes).to include(project.project_creation_wizard_work_package_comment)
      expect(artifact_work_package.last_journal.notes).to include(/<mention[^>]+>@#{assignee_user.name}<\/mention>/)
      expect(artifact_work_package.last_journal.notes).to include(/data-type="user"/)
    end

    context "when 'Assignee when submitted' is not configured" do
      before do
        project.update(project_creation_wizard_assignee_custom_field_id: nil)
      end

      it "creates the artifact work package without an assignee and without a mention in the comment" do
        result = instance.call

        expect(result.errors.full_messages).to be_empty
        project = result.result

        artifact_work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
        expect(artifact_work_package.assigned_to).to be_nil
        expect(artifact_work_package.last_journal.notes).not_to include("<mention")
        expected_path = Rails.application.routes.url_helpers.project_creation_wizard_path(project)
        expect(artifact_work_package.last_journal.notes).to include(expected_path)
      end
    end

    context "when assignee is a group" do
      let(:group) { create(:group, firstname: "test group") }

      it "mentions the group" do
        project.members << create(:member, principal: group, project: p, roles: [role])
        project.send("#{user_custom_field.attribute_name}=", group.id)

        result = instance.call
        project = result.result

        artifact_work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
        expect(artifact_work_package.last_journal.notes).not_to be_empty
        expect(artifact_work_package.last_journal.notes).to include(project.project_creation_wizard_work_package_comment)
        expect(artifact_work_package.last_journal.notes).to include(/<mention[^>]+>@#{group.name}<\/mention>/)
        expect(artifact_work_package.last_journal.notes).to include(/data-type="group"/)
      end
    end

    it "adds a relative link to the project creation wizard in the description and journal comment" do
      result = instance.call
      project = result.result

      artifact_work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
      expected_path = Rails.application.routes.url_helpers.project_creation_wizard_path(project)
      expected_link_text = I18n.t("settings.project_initiation_request.wizard_status_button.project_mandate")
      expected_link = "[#{expected_link_text}](#{expected_path})"

      expect(artifact_work_package.last_journal.notes).to include(expected_link)
      expect(artifact_work_package.description)
        .to include("This work package was automatically created upon completion of the Project mandate workflow.")
      expect(artifact_work_package.description).to include(expected_link)
    end

    it "sends only one notification for the work package comment" do
      clear_enqueued_jobs
      result = instance.call

      project = result.result
      artifact_work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)

      expect(enqueued_jobs).to include(a_hash_including(job: Notifications::WorkflowJob))
      workflow_jobs = enqueued_jobs.select { it[:job] == Notifications::WorkflowJob }

      # There should be exactly 2 WorkflowJobs: one for the attachment journal,
      # one for the work package journal
      journals = workflow_jobs.pluck(:args)
                              .map { |_state_arg, journal_arg, _send_notification| journal_arg["_aj_globalid"] }
                              .map { |journal_gid| GlobalID::Locator.locate(journal_gid) }
      expect(journals.pluck(:journable_type, :journable_id)).to contain_exactly(
        [WorkPackage.name, artifact_work_package.id],
        [Attachment.name, artifact_work_package.attachments.first.id]
      )
    end

    context "when artifact storage is internal" do
      it "attaches directly to the work package" do
        project.update(project_creation_wizard_artifact_export_type: "attachment")
        result = instance.call
        project = result.result

        artifact_work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
        expect(artifact_work_package.attachments.count).to eq(1)
        attachment = artifact_work_package.attachments.first
        date = Date.current.iso8601
        expect(attachment.content_type).to eq "application/pdf"
        regex = /#{project.identifier}_Project_mandate_#{artifact_work_package.status.name}_#{date}_\d+-\d+.pdf/
        expect(attachment.filename).to match regex
      end
    end

    context "when artifact storage is project storage" do
      let(:storage) { create(:nextcloud_storage_with_local_connection) }
      let(:project_storage) { create(:project_storage, project:, storage:, project_folder_id: "/project_folder") }

      let(:service_result) { ServiceResult.success(result: nil) }

      before do
        project.update(
          project_creation_wizard_artifact_export_type: "file_link",
          project_creation_wizard_artifact_export_storage: project_storage.id
        )

        allow(Storages::UploadFileService)
          .to receive(:call)
                .and_return(service_result)
      end

      it "calls the nextcloud storage service" do
        result = instance.call
        project = result.result

        expect(result).to be_success
        artifact_work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
        expect(artifact_work_package.attachments.count).to eq(0)

        date = Date.current.iso8601
        expect(Storages::UploadFileService)
          .to have_received(:call)
          .with(container: artifact_work_package,
                project_storage:,
                file_path: "Project mandate",
                filename: /#{project.identifier}_Project_mandate_#{artifact_work_package.status.name}_#{date}_\d+-\d+.pdf/,
                file_data: instance_of(StringIO))
      end

      context "with another default language", with_settings: { default_language: :de } do
        it "calls the nextcloud storage service using the localized name" do
          result = instance.call
          project = result.result

          expect(result).to be_success
          artifact_work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
          expect(artifact_work_package.attachments.count).to eq(0)

          date = Date.current.iso8601
          expect(Storages::UploadFileService)
            .to have_received(:call)
                  .with(container: artifact_work_package,
                        project_storage:,
                        file_path: "Projektmandat",
                        filename: /#{project.identifier}_Project_mandate_#{artifact_work_package.status.name}_#{date}_\d+-\d+.pdf/,
                        file_data: instance_of(StringIO))
        end
      end

      context "when service call fails" do
        let(:service_result) do
          ServiceResult.failure(result: nil).tap do |result|
            result.errors.add(:base, "Something happened!")
          end
        end

        it "keeps the work package, but shows an error" do
          result = instance.call
          project = result.result

          expect(Storages::UploadFileService)
            .to have_received(:call)

          # The outer service is successful, but an error is added
          expect(result).to be_success
          expect(result.errors[:base]).to include "Something happened!"

          artifact_work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
          expect(artifact_work_package.attachments.count).to eq(0)
        end
      end
    end

    context "with required work package custom fields" do
      shared_let(:required_wp_custom_field) do
        create(:work_package_custom_field,
               field_format: "string",
               name: "Required Field",
               is_required: true,
               projects: [project],
               types: [type])
      end

      it "bypasses custom field validation and creates the artifact work package" do
        result = instance.call

        expect(result).to be_success
        expect(result.errors.full_messages).to be_empty
        project = result.result
        expect(project.project_creation_wizard_artifact_work_package_id).to be_present

        artifact_work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
        expect(artifact_work_package).to be_persisted
        expect(artifact_work_package.custom_value_for(required_wp_custom_field)&.value).to be_blank
      end
    end

    describe "notification email" do
      context "when confirmation email is enabled" do
        before do
          project.update(
            project_creation_wizard_send_confirmation_email: true,
            project_creation_wizard_notification_text: "Thank you for submitting your request"
          )
        end

        it "sends the creation wizard submitted email" do
          allow(ProjectArtifactsMailer).to receive(:creation_wizard_submitted).and_call_original

          result = instance.call

          expect(result).to be_success
          expect(ProjectArtifactsMailer).to have_received(:creation_wizard_submitted)
        end

        it "sends the email with correct parameters" do
          mailer_double = instance_double(ActionMailer::MessageDelivery)
          allow(mailer_double).to receive(:deliver_later)

          allow(ProjectArtifactsMailer)
            .to receive(:creation_wizard_submitted)
                  .with(current_user, project, instance_of(WorkPackage))
                  .and_return(mailer_double)

          instance.call

          expect(mailer_double).to have_received(:deliver_later)
        end

        it "enqueues the email for delivery" do
          expect do
            instance.call
          end.to have_enqueued_job(Mails::MailerJob)
                   .with("ProjectArtifactsMailer", "creation_wizard_submitted", "deliver_now",
                         { args: [current_user, project, instance_of(WorkPackage)] })
        end
      end

      context "when confirmation email is disabled" do
        before do
          project.update(project_creation_wizard_send_confirmation_email: false)
        end

        it "does not send the creation wizard submitted email" do
          allow(ProjectArtifactsMailer).to receive(:creation_wizard_submitted)

          result = instance.call

          expect(result).to be_success
          expect(ProjectArtifactsMailer).not_to have_received(:creation_wizard_submitted)
        end

        it "does not enqueue any email delivery job" do
          expect do
            instance.call
          end.not_to have_enqueued_job(Mails::MailerJob)
                       .with("ProjectArtifactsMailer", "creation_wizard_submitted", "deliver_now", anything)
        end
      end
    end
  end

  context "when contract is invalid" do
    before do
      allow(mocked_contract).to receive_messages(
                                  validate: false,
                                  errors: ActiveModel::Errors.new(project).tap do |errors|
                                    errors.add(:base, :error_unauthorized)
                                  end
                                )
    end

    it "does not create any work packages" do
      result = instance.call

      expect(result.errors.full_messages).not_to be_empty
      project = result.result
      expect(project.project_creation_wizard_artifact_work_package_id).to be_nil
      expect(project.work_packages.count).to be_zero
    end
  end
end
