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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects::CreationWizard
  module ArtifactExporter
    private

    def store_attachment_locally?
      project.project_creation_wizard_artifact_export_type == "attachment"
    end

    def project_storage
      return @project_storage if defined?(@project_storage)

      @project_storage = project
        .project_storages
        .find_by(id: project.project_creation_wizard_artifact_export_storage)
    end

    def create_pdf_export!
      Project::PDFExport::ProjectInitiation.new(project).export!
    end

    def upload_artifact_to_storage
      export = create_pdf_export!

      Storages::UploadFileService
        .call(
          container: artifact_work_package,
          project_storage:,
          file_path: artifact_storage_folder_name,
          file_data: StringIO.new(export.content),
          filename: export.title
        )
    end

    def artifact_storage_folder_name
      I18n.t(project.project_creation_wizard_artifact_name,
             locale: Setting.default_language,
             default: :project_initiation_request,
             scope: "settings.project_initiation_request.name.options")
    end
  end
end
