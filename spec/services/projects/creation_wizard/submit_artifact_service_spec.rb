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

RSpec.describe Projects::CreationWizard::SubmitArtifactService do
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
      project_creation_wizard_status_when_submitted_id: status_new.id,
      project_creation_wizard_artifact_export_type: "attachment"
    ).tap do |p|
      p.members << create(:member, principal: current_user, project: p, roles: [role])
    end
  end

  let(:instance) do
    described_class.new(user: current_user, project:)
  end

  before do
    login_as current_user
  end

  context "when no artifact work package exists" do
    let(:create_service_result) { ServiceResult.success(result: project) }
    let(:create_service_instance) { instance_double(Projects::CreationWizard::CreateArtifactWorkPackageService, call: create_service_result) }

    before do
      project.update!(project_creation_wizard_artifact_work_package_id: nil)

      allow(Projects::CreationWizard::CreateArtifactWorkPackageService)
        .to receive(:new)
        .with(user: current_user, model: project)
        .and_return(create_service_instance)
    end

    it "delegates to CreateArtifactWorkPackageService" do
      result = instance.call

      expect(result).to be_success
      expect(Projects::CreationWizard::CreateArtifactWorkPackageService).to have_received(:new)
      expect(create_service_instance).to have_received(:call)
    end

    it "returns the result from CreateArtifactWorkPackageService" do
      result = instance.call

      expect(result).to eq(create_service_result)
    end
  end

  context "when the artifact work package already exists" do
    shared_let(:work_package) do
      create(:work_package, project:, type:, status: status_new, subject: "Existing artifact")
    end

    let(:upload_result) { ServiceResult.success(result: nil) }
    let(:upload_service_instance) { instance_double(Projects::CreationWizard::UploadArtifactService, call: upload_result) }

    before do
      project.update!(project_creation_wizard_artifact_work_package_id: work_package.id)

      allow(Projects::CreationWizard::UploadArtifactService)
        .to receive(:new)
        .with(user: current_user, project:, work_package:)
        .and_return(upload_service_instance)
    end

    it "delegates to UploadArtifactService" do
      result = instance.call

      expect(result).to be_success
      expect(result.result).to eq(project)
      expect(Projects::CreationWizard::UploadArtifactService).to have_received(:new)
      expect(upload_service_instance).to have_received(:call)
    end

    it "does not call CreateArtifactWorkPackageService" do
      allow(Projects::CreationWizard::CreateArtifactWorkPackageService).to receive(:new)

      instance.call

      expect(Projects::CreationWizard::CreateArtifactWorkPackageService).not_to have_received(:new)
    end

    context "when upload fails" do
      let(:upload_result) do
        ServiceResult.failure(result: nil).tap do |result|
          result.errors.add(:base, "Upload failed!")
        end
      end

      it "returns a successful result with errors from the upload" do
        result = instance.call

        expect(result).to be_success
        expect(result.errors[:base]).to include("Upload failed!")
      end
    end
  end

  context "when the artifact work package id is dangling (work package was deleted)" do
    let(:create_service_result) { ServiceResult.success(result: project) }
    let(:create_service_instance) { instance_double(Projects::CreationWizard::CreateArtifactWorkPackageService, call: create_service_result) }

    before do
      project.update!(project_creation_wizard_artifact_work_package_id: 99999)

      allow(Projects::CreationWizard::CreateArtifactWorkPackageService)
        .to receive(:new)
        .with(user: current_user, model: project)
        .and_return(create_service_instance)
    end

    it "delegates to CreateArtifactWorkPackageService" do
      result = instance.call

      expect(result).to be_success
      expect(Projects::CreationWizard::CreateArtifactWorkPackageService).to have_received(:new)
    end
  end
end
