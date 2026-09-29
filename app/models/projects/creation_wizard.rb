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

module Projects::CreationWizard
  ARTIFACT_NAME_OPTIONS = %w[project_creation_wizard project_initiation_request project_mandate].freeze
  DEFAULT_ARTIFACT_NAME_OPTION = "project_creation_wizard"
  DEFAULT_ARTIFACT_EXPORT_TYPE = "attachment"

  extend ActiveSupport::Concern

  included do
    store_attribute :settings, :project_creation_wizard_enabled, :boolean
    store_attribute :settings, :project_creation_wizard_artifact_name, :string
    store_attribute :settings, :project_creation_wizard_work_package_type_id, :integer
    store_attribute :settings, :project_creation_wizard_status_when_submitted_id, :integer
    store_attribute :settings, :project_creation_wizard_send_confirmation_email, :boolean
    store_attribute :settings, :project_creation_wizard_assignee_custom_field_id, :integer
    store_attribute :settings, :project_creation_wizard_notification_text, :string
    store_attribute :settings, :project_creation_wizard_work_package_comment, :string
    store_attribute :settings, :project_creation_wizard_artifact_work_package_id, :integer
    store_attribute :settings, :project_creation_wizard_artifact_export_type, :string
    store_attribute :settings, :project_creation_wizard_artifact_export_storage, :string

    # The store_attribute default cannot be used here, because the default is not returned
    # when the JSON defintion is present but it's nil.
    def project_creation_wizard_artifact_name
      super.presence || DEFAULT_ARTIFACT_NAME_OPTION
    end

    def project_creation_wizard_work_package_type_id
      super.presence || project_creation_wizard_default_work_package_type&.id
    end

    def project_creation_wizard_artifact_export_type
      super.presence || DEFAULT_ARTIFACT_EXPORT_TYPE
    end

    def project_creation_wizard_status_when_submitted_id
      super.presence || project_creation_wizard_default_status_when_submitted&.id
    end

    def project_creation_wizard_work_package_comment
      super.presence ||
        I18n.t(
          "settings.project_initiation_request.submission.work_package_comment_default",
          project_name: name
        )
    end

    def project_creation_wizard_default_work_package_type
      enabled_types.first
    end

    def project_creation_wizard_default_status_when_submitted
      type_variant(project_creation_wizard_default_work_package_type)&.statuses&.first
    end
  end
end
