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

module CustomFields
  class ProjectAdminSettingsForm < ApplicationForm
    def initialize(mode:, disabled:)
      super()

      @mode = mode
      @disabled = disabled
    end

    form do |settings_form|
      if mode != "all"
        settings_form.check_box(
          name: :project_level_value_management,
          id: "custom_field_project_level_value_management_#{mode}",
          label: attribute_name(:project_level_value_management),
          caption: I18n.t("custom_fields.project_specific_values.project_admins.value_management_caption"),
          disabled:
        )
      end

      settings_form.check_box(
        name: :allow_additional_project_values,
        id: "custom_field_allow_additional_project_values_#{mode}",
        label: attribute_name(:allow_additional_project_values),
        caption: I18n.t("custom_fields.project_specific_values.project_admins.additional_values_caption"),
        disabled:
      )
    end

    private

    attr_reader :mode, :disabled
  end
end
