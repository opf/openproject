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

module Projects
  class SettingsContract < ::BaseContract
    attribute :settings

    validate :validate_settings
    validate :validate_submission_fields

    protected

    def validate_settings
      unauthorized_settings_change =
        has_changed_setting?("deactivate_work_package_attachments") &&
          !user.allowed_in_project?(:manage_files_in_project, model)

      errors.add :base, :error_unauthorized if unauthorized_settings_change
    end

    def validate_submission_fields
      return unless model.project_creation_wizard_enabled?
      return unless updating_submission_settings?

      validate_work_package_type
      validate_status_when_submitted
      validate_assignee_custom_field
      validate_notification_text
    end

    def validate_work_package_type
      if model.project_creation_wizard_work_package_type_id.blank?
        errors.add :project_creation_wizard_work_package_type_id, :blank
      else
        unless model.types.exists?(id: model.project_creation_wizard_work_package_type_id)
          errors.add :project_creation_wizard_work_package_type_id, :inclusion
        end
      end
    end

    def validate_status_when_submitted
      if model.project_creation_wizard_status_when_submitted_id.blank?
        errors.add :project_creation_wizard_status_when_submitted_id, :blank
      else
        type = Type.find_by(id: model.project_creation_wizard_work_package_type_id)
        unless type.statuses.exists?(id: model.project_creation_wizard_status_when_submitted_id)
          errors.add :project_creation_wizard_status_when_submitted_id, :inclusion
        end
      end
    end

    def validate_assignee_custom_field
      return if model.project_creation_wizard_assignee_custom_field_id.blank?

      valid_custom_field = model.available_custom_fields
                                .where(field_format: "user", multi_value: false)
                                .exists?(id: model.project_creation_wizard_assignee_custom_field_id)
      unless valid_custom_field
        errors.add :project_creation_wizard_assignee_custom_field_id, :inclusion
      end
    end

    def validate_notification_text
      if model.project_creation_wizard_send_confirmation_email == true &&
         model.project_creation_wizard_notification_text.blank?
        errors.add :project_creation_wizard_notification_text, :blank
      end
    end

    def updating_submission_settings?
      has_changed_setting?("project_creation_wizard_assignee_custom_field_id") ||
        has_changed_setting?("project_creation_wizard_work_package_type_id") ||
        has_changed_setting?("project_creation_wizard_status_when_submitted_id") ||
        has_changed_setting?("project_creation_wizard_send_confirmation_email") ||
        has_changed_setting?("project_creation_wizard_notification_text") ||
        has_changed_setting?("project_creation_wizard_work_package_comment")
    end

    private

    def has_changed_setting?(key)
      model.settings_changed? && model.settings_change.any? { |setting| setting.key?(key) }
    end
  end
end
