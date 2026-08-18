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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackages
  module TypeArtefactExport
    class ExportOnStatusChangeService
      attr_reader :current_user, :work_package

      delegate :project, :type, :type_variant, to: :work_package

      def initialize(current_user:, work_package:)
        @current_user = current_user
        @work_package = work_package
      end

      def self.applicable?(work_package:, changes:)
        return false if changes["status_id"].blank?
        return false unless work_package.type_variant.artefact_export_enabled?

        # The creation wizard runs its own export for its artifact work package;
        # skip it here to avoid generating the PDF twice.
        !creation_wizard_artifact_work_package?(work_package)
      end

      def self.creation_wizard_artifact_work_package?(work_package)
        work_package.project.project_creation_wizard_artifact_work_package_id.to_s == work_package.id.to_s
      end

      def call!(changes:)
        return unless self.class.applicable?(work_package:, changes:)

        export_and_store!
      rescue ::Exports::ExportError => e
        Rails.logger.error("Artefact export failed for work package ##{work_package.id}: #{e.message}")
      end

      private

      def export_and_store!
        settings = type_variant.pdf_export_templates.settings_for("artefact")
        export = WorkPackage::PDFExport::Artefact.new(work_package, settings).export!

        case type_variant.artefact_export_mode
        when Type::ArtefactExport::ATTACHMENT
          store_as_attachment(export)
        when Type::ArtefactExport::FILE_LINK
          User.execute_as_admin(current_user) do
            upload_to_storage(export)
          end
        end
      end

      def store_as_attachment(export)
        attachment = work_package.attachments.create(author: current_user, file: uploaded_file(export))
        if attachment.persisted?
          journalize_attachment(attachment.author)
        else
          Rails.logger.error(
            "Failed to attach artefact to work package ##{work_package.id}: " \
            "#{attachment.errors.full_messages.join(', ')}"
          )
        end
      end

      def uploaded_file(export)
        OpenProject::Files.create_uploaded_file(
          name: export.title,
          content_type: export.mime_type,
          content: export.content,
          binary: true
        )
      end

      # Creating the attachment through the association does not create a work package
      # journal on its own, so the artefact would only surface in the Activity tab after
      # the next unrelated change. Create the journal explicitly so it shows up right away.
      def journalize_attachment(author)
        OpenProject::Mutex.with_advisory_lock_transaction(work_package) do
          work_package.add_journal(user: author)
          work_package.touch_and_save_journals
        end
      end

      def upload_to_storage(export)
        project_storage = target_project_storage
        if project_storage.nil?
          log_missing_storage
          return
        end

        result = upload(export, project_storage)
        return if result.success?

        Rails.logger.error("Artefact upload failed for work package ##{work_package.id}: #{result.message}")
      end

      def upload(export, project_storage)
        Storages::UploadFileService.call(
          container: work_package,
          project_storage:,
          file_path: artefact_folder_name(project_storage.storage),
          filename: export.title,
          file_data: StringIO.new(export.content)
        )
      end

      def log_missing_storage
        Rails.logger.info(
          "No automatically-managed Nextcloud storage for project ##{project.id}; " \
          "skipping artefact upload for work package ##{work_package.id}"
        )
      end

      # A Type is global, so it cannot store a project-scoped storage id.
      # Use the first automatically-managed Nextcloud project
      # storage of the work package's project
      def target_project_storage
        project.project_storages
               .automatic
               .includes(:storage)
               .find { |project_storage| project_storage.storage.provider_type_nextcloud? }
      end

      # sanitize managed project folders (according to
      # Storages::Adapters::Providers::Nextcloud::ManagedFolderIdentifier):
      def artefact_folder_name(storage)
        type.name
            .tr("/\\", "|")
            .tr(storage.forbidden_file_name_characters, "_")
      end
    end
  end
end
