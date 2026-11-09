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

module OpenProject
  module Admin
    module Settings
      # @logical_path OpenProject/Admin/Settings
      class ColumnSelectionComponentPreview < ViewComponent::Preview
        COLUMNS = [
          { id: "id", name: "ID" },
          { id: "subject", name: "Subject" },
          { id: "status", name: "Status" },
          { id: "assigned_to", name: "Assignee" },
          { id: "priority", name: "Priority" }
        ].freeze

        # Column Selection Component
        # ----------------
        # This is a wrapper component around the `opce-draggable-autocompleter` AngularJS component.
        # It is used to configure columns and their order for certain views.
        #
        # @param name [Symbol] text "Name of the setting. This determines the name and the ID of the input element."
        # @param columns [Array] text "All available columns, provided as id-name pairs."
        # @param selected [Array] text "The current selection of columns, provided as id-name pairs."
        # @param protected [Array] text "Columns which cannot be removed from the selection, provided as id-name pairs"
        def default(name: :default_columns, columns: COLUMNS, selected: COLUMNS.first(3), protected: COLUMNS.first(1))
          render(
            ::Admin::Settings::ColumnSelectionComponent.new(name:, columns:, selected:, protected:)
          )
        end

        def without_protected_columns
          render(
            ::Admin::Settings::ColumnSelectionComponent.new(
              name: :default_columns,
              columns: COLUMNS,
              selected: COLUMNS.first(3),
              protected: []
            )
          )
        end

        def without_selected_columns
          render(
            ::Admin::Settings::ColumnSelectionComponent.new(
              name: :default_columns,
              columns: COLUMNS,
              selected: [],
              protected: []
            )
          )
        end
      end
    end
  end
end
