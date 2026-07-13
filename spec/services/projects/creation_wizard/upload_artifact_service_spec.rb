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

RSpec.describe Projects::CreationWizard::UploadArtifactService do
  shared_let(:status_new) { create(:status, name: "New") }
  shared_let(:type) { create(:type, name: "Project initiation") }
  shared_let(:current_user) { create(:user, lastname: "current_user") }
  shared_let(:role) do
    create(:project_role, permissions: %i[
             add_work_packages
             view_project_attributes
           ])
  end
  shared_let(:default_priority) { create(:default_priority) }
  shared_let(:project) do
    create(
      :project,
      name: "Important Project",
      types: [type],
      project_creation_wizard_artifact_name: "project_mandate",
      project_creation_wizard_enabled: true,
      project_creation_wizard_work_package_type_id: type.id,
      project_creation_wizard_status_when_submitted_id: status_new.id
    ).tap do |p|
      p.members << create(:member, principal: current_user, project: p, roles: [role])
    end
  end

  shared_let(:work_package) do
    create(
      :work_package,
      project:,
      type:,
      status: status_new,
      subject: "Artifact Work Package"
    )
  end

  let(:instance) do
    described_class.new(user: current_user, project:, work_package:)
  end

  before do
    login_as current_user
  end

  context "when artifact storage is internal (attachment)" do
    before do
      project.update(project_creation_wizard_artifact_export_type: "attachment")
    end

    it "adds the PDF as an attachment to the work package" do
      initial_attachment_count = work_package.attachments.count

      result = instance.call

      expect(result).to be_success
      work_package.reload
      expect(work_package.attachments.count).to eq(initial_attachment_count + 1)

      attachment = work_package.attachments.last
      date = Date.current.iso8601
      expect(attachment.content_type).to eq "application/pdf"
      expect(attachment.filename).to match(/.*_Project_mandate_#{status_new.name}_#{date}_\d+-\d+.pdf/)
      expect(attachment.author).to eq(current_user)
    end

    context "when work package already has an attachment" do
      before do
        work_package.attachments.create(
          author: current_user,
          file: OpenProject::Files.create_uploaded_file(
            name: "existing_file.pdf",
            content_type: "application/pdf",
            content: "old content",
            binary: true
          )
        )
      end

      it "adds a new attachment without removing the existing one" do
        initial_count = work_package.attachments.count

        result = instance.call

        expect(result).to be_success
        work_package.reload
        expect(work_package.attachments.count).to eq(initial_count + 1)
      end
    end
  end

  context "when artifact storage is project storage (file link)" do
    let(:storage) { create(:nextcloud_storage_with_local_connection) }
    let(:project_storage) { create(:project_storage, project:, storage:, project_folder_id: "/project_folder") }
    let(:service_result) { ServiceResult.success(result: nil) }

    before do
      project.update!(
        project_creation_wizard_artifact_export_type: "file_link",
        project_creation_wizard_artifact_export_storage: project_storage.id
      )

      allow(Storages::UploadFileService)
        .to receive(:call)
        .and_return(service_result)
    end

    it "uploads the artifact to the project storage" do
      result = instance.call

      expect(result).to be_success
      work_package.reload
      expect(work_package.attachments.count).to eq(0)

      date = Date.current.iso8601
      expect(Storages::UploadFileService)
        .to have_received(:call)
        .with(container: work_package,
              project_storage:,
              file_path: "Project mandate",
              filename: /.*_Project_mandate_#{status_new.name}_#{date}_\d+-\d+.pdf/,
              file_data: instance_of(StringIO))
    end

    context "when storage upload fails" do
      let(:service_result) do
        ServiceResult.failure(result: nil).tap do |result|
          result.errors.add(:base, "Storage upload failed!")
        end
      end

      it "returns a failure result" do
        result = instance.call

        expect(result).to be_failure
        expect(Storages::UploadFileService).to have_received(:call)
      end
    end

    context "when project storage is not configured" do
      before do
        project.update(project_creation_wizard_artifact_export_storage: nil)
      end

      it "returns a failure result with storage error" do
        result = instance.call

        expect(result).to be_failure
        expect(result.message).to eq(I18n.t("projects.wizard.create_artifact_storage_error"))
      end

      it "does not call the storage upload service" do
        instance.call

        expect(Storages::UploadFileService).not_to have_received(:call)
      end
    end

    context "when project storage does not exist (invalid id)" do
      before do
        project.update(project_creation_wizard_artifact_export_storage: 99999)
      end

      it "returns a failure result" do
        result = instance.call

        expect(result).to be_failure
      end
    end
  end
end
