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
    class TemplateExcludedRolesForm < ApplicationForm
      attr_reader :project

      def initialize(project:)
        super()

        @project = project
      end

      form do |f|
        f.autocompleter(
          name: "excluded_role_ids",
          scope_name_to_model: false,
          label: I18n.t("projects.settings.template.members.excluded_roles_label"),
          caption: I18n.t("projects.settings.template.members.excluded_roles_caption"),
          wrapper_data_attributes: { "test-selector": "excluded_role_ids" },
          autocomplete_options: {
            multiple: true,
            decorated: true,
            clearable: true,
            focusDirectly: false,
            inputValue: selected_role_ids
          }
        ) do |list|
          available_roles.find_each do |role|
            list.option(
              label: role.name,
              value: role.id,
              selected: selected_role_ids.include?(role.id)
            )
          end
        end

        f.submit(
          name: :submit,
          label: I18n.t(:button_save),
          scheme: :primary
        )
      end

      private

      def available_roles
        ProjectRole.givable.ordered_by_builtin_and_position
      end

      def selected_role_ids
        @selected_role_ids ||= Array(project.excluded_role_ids_on_copy).map(&:to_i)
      end
    end
  end
end
