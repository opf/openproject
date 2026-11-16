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

module Admin
  module Settings
    class WorkPackagesGeneralForm < ApplicationForm
      INLINE_HIGHLIGHT_EFFECT = {
        show_when_value_selected_target: "effect",
        target_name: "work_package_list_default_highlighting_mode",
        value: "inline"
      }.freeze

      settings_form do |sf|
        sf.check_box(name: :cross_project_work_package_relations)
        sf.check_box(name: :display_subprojects_work_packages)
        sf.check_box(name: :work_package_startdate_is_adddate)
        sf.select_list(
          name: :work_package_list_default_highlighting_mode,
          values: highlight_mode_options,
          data: {
            show_when_value_selected_target: "cause",
            target_name: "work_package_list_default_highlighting_mode"
          },
          input_width: :medium
        )
        sf.group(
          hidden: Setting[:work_package_list_default_highlighting_mode] != "inline",
          data: INLINE_HIGHLIGHT_EFFECT
        ) do |group|
          group.check_box_group(
            include_hidden: true,
            name: :work_package_list_default_highlighted_attributes,
            values: highlightable_column_options,
            data: INLINE_HIGHLIGHT_EFFECT
          )
        end
        sf.fieldset_group(title: I18n.t(:setting_column_options)) do |fg|
          fg.html_content do
            render(
              Admin::Settings::ColumnSelectionComponent.new(
                name: :work_package_list_default_columns,
                columns: helpers.work_packages_columns_options,
                selected: helpers.selected_work_packages_columns_options,
                protected: helpers.protected_work_packages_columns_options
              )
            )
          end
        end
      end

      private

      def highlight_mode_options
        Query::Highlighting::QUERY_HIGHLIGHTING_MODES.map do |mode|
          [I18n.t("settings.highlighting.mode_long.#{mode}"), mode.to_s]
        end
      end

      def highlightable_column_options
        Query.available_columns(nil).select(&:highlightable).map do |column|
          [column.caption, column.name.to_s]
        end
      end
    end
  end
end
