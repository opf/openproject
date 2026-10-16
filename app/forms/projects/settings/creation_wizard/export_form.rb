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
module Projects
  module Settings
    module CreationWizard
      class ExportForm < ApplicationForm
        form do |f|
          f.radio_button_group(
            name: :project_creation_wizard_artifact_export_type,
            label: I18n.t("projects.settings.creation_wizard.export.pdf_file_storage")
          ) do |group|
            group.radio_button(
              value: :attachment,
              checked: checked?(:attachment),
              label: I18n.t("projects.settings.creation_wizard.export.label_attachment_export"),
              caption: I18n.t("projects.settings.creation_wizard.export.description_attachment_export"),
              data: { action: "projects--settings--initiation-request--export-artifact#updateForm" }
            )
            group.radio_button(
              value: :file_link,
              checked: checked?(:file_link),
              label: file_link_label,
              caption: I18n.t("projects.settings.creation_wizard.export.description_file_link_export"),
              disabled: file_storages.empty?,
              data: { action: "projects--settings--initiation-request--export-artifact#updateForm" }
            )
          end

          if file_storages.any?
            f.group(display: show_file_storage_select_list_initially? ? :block : :none,
                    data: {
                      "projects--settings--initiation-request--export-artifact-target": "projectStoragesSelectList"
                    }) do |storage_select|
              storage_select.select_list(
                name: :project_creation_wizard_artifact_export_storage,
                label: I18n.t("projects.settings.creation_wizard.export.external_file_storage"),
                caption: I18n.t("projects.settings.creation_wizard.export.description_file_storage_selection")
              ) do |list|
                file_storages.each do |project_storage|
                  list.option(label: project_storage.storage.typed_label, value: project_storage.id)
                end
              end
            end
          end

          f.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary)
        end

        private

        def file_link_export_enabled?
          file_storages.any?
        end

        def checked?(value)
          value == (model.project_creation_wizard_artifact_export_type&.to_sym || :attachment)
        end

        def file_link_label
          label = I18n.t("projects.settings.creation_wizard.export.label_file_link_export")
          if file_storages.any?
            label
          else
            "#{label} (#{I18n.t('projects.settings.creation_wizard.export.unavailable')})"
          end
        end

        def file_storages
          @file_storages ||= model.project_storages
                                  .automatic
                                  .includes(:storage)
                                  .filter { |project_storages| project_storages.storage.provider_type_nextcloud? }
        end

        def show_file_storage_select_list_initially?
          model.project_creation_wizard_artifact_export_type&.to_sym == :file_link
        end
      end
    end
  end
end
