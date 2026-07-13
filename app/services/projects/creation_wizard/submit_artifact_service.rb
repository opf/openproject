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

module Projects::CreationWizard
  class SubmitArtifactService
    attr_reader :user, :project

    def initialize(user:, project:)
      @user = user
      @project = project
    end

    def call
      if artifact_work_package_exists?
        upload_artifact
      else
        create_artifact_work_package
      end
    end

    private

    def artifact_work_package_exists?
      WorkPackage.exists?(project.project_creation_wizard_artifact_work_package_id)
    end

    def create_artifact_work_package
      CreateArtifactWorkPackageService
        .new(user:, model: project)
        .call
    end

    def upload_artifact
      work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
      upload_call = UploadArtifactService
        .new(user:, project:, work_package:)
        .call

      service_call = ServiceResult.success(result: project)
      upload_call.on_failure do
        service_call.merge!(upload_call, without_success: true)
      end
      service_call
    end
  end
end
