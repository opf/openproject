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

module Projects
  module Settings
    module CreationWizard
      class SubmissionForm < ApplicationForm
        form do |f|
          f.select_list(
            name: :project_creation_wizard_work_package_type_id,
            label: I18n.t("settings.project_initiation_request.submission.work_package_type"),
            caption: I18n.t("settings.project_initiation_request.submission.work_package_type_caption"),
            required: true,
            input_width: :large,
            data: {
              action: "change->refresh-on-form-changes#triggerTurboStream"
            }
          ) do |list|
            model.types.each do |type|
              list.option(
                value: type.id,
                label: type.name,
                selected: type.id == model.project_creation_wizard_work_package_type_id
              )
            end
          end

          f.select_list(
            name: :project_creation_wizard_status_when_submitted_id,
            label: I18n.t("settings.project_initiation_request.submission.status_when_submitted"),
            caption: I18n.t("settings.project_initiation_request.submission.status_when_submitted_caption"),
            required: true,
            input_width: :large
          ) do |list|
            # Statuses of the selected WP type
            type_id = model.project_creation_wizard_work_package_type_id

            if type_id.present?
              type = Type.find_by(id: type_id)
              type&.statuses&.each do |status|
                list.option(
                  value: status.id,
                  label: status.name,
                  selected: status.id == model.project_creation_wizard_status_when_submitted_id
                )
              end
            end
          end

          f.autocompleter(
            name: :project_creation_wizard_assignee_custom_field_id,
            label: I18n.t("settings.project_initiation_request.submission.assignee"),
            caption: helpers.t("settings.project_initiation_request.submission.assignee_caption_html"),
            required: false,
            input_width: :large,
            autocomplete_options: {
              component: "opce-autocompleter",
              decorated: true,
              focus_directly: false
            }
          ) do |list|
            model.available_custom_fields.where(field_format: "user", multi_value: false).order(:name).each do |custom_field|
              list.option(
                value: custom_field.id,
                label: custom_field.name,
                selected: custom_field.id == model.project_creation_wizard_assignee_custom_field_id
              )
            end
          end

          f.rich_text_area(
            name: :project_creation_wizard_work_package_comment,
            label: I18n.t("settings.project_initiation_request.submission.work_package_comment"),
            caption: I18n.t("settings.project_initiation_request.submission.work_package_comment_caption"),
            required: false,
            rich_text_options: {
              showAttachments: false,
              editorType: "constrained"
            }
          )

          f.check_box(
            name: :project_creation_wizard_send_confirmation_email,
            label: I18n.t("settings.project_initiation_request.submission.send_confirmation_email"),
            checked: model.project_creation_wizard_send_confirmation_email.presence,
            data: {
              "show-when-checked-target": "cause",
              target_name: "send_confirmation_email"
            }
          )

          f.rich_text_area(
            name: :project_creation_wizard_notification_text,
            label: I18n.t("settings.project_initiation_request.submission.confirmation_email_text"),
            required: true,
            value: model.project_creation_wizard_notification_text.presence || I18n.t(
              "settings.project_initiation_request.submission.confirmation_email_default", project_name: model.name
            ),
            rich_text_options: {
              showAttachments: false,
              editorType: "constrained"
            },
            wrapper_classes: model.project_creation_wizard_send_confirmation_email.blank? ? "d-none" : "",
            wrapper_data_attributes: {
              "show-when-checked-target": "effect",
              target_name: "send_confirmation_email",
              "visibility-class": "d-none"
            }
          )

          f.submit(
            name: :submit,
            label: I18n.t("button_save"),
            scheme: :primary
          )
        end
      end
    end
  end
end
