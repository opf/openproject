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
  class UploadArtifactService
    include ArtifactExporter

    attr_reader :user, :project, :artifact_work_package

    def initialize(user:, project:, work_package:)
      @user = user
      @project = project
      @artifact_work_package = work_package
    end

    def call
      if store_attachment_locally?
        return add_attachment_locally
      end

      if project_storage.nil?
        return ServiceResult.failure(message: I18n.t("projects.wizard.create_artifact_storage_error"))
      end

      upload_artifact_to_storage
    end

    private

    def add_attachment_locally
      export = create_pdf_export!
      file = OpenProject::Files.create_uploaded_file(
        name: export.title,
        content_type: export.mime_type,
        content: export.content,
        binary: true
      )

      attachment = artifact_work_package.attachments.create(
        author: user,
        file:
      )

      if attachment.persisted?
        ServiceResult.success(result: attachment)
      else
        ServiceResult.failure(result: attachment, errors: attachment.errors)
      end
    end
  end
end
