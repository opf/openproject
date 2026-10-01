# frozen_string_literal: true

# -- copyright
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
# ++

module WorkPackages
  module Exports
    class ColumnSelectionComponent < ApplicationComponent
      include WorkPackagesHelper

      attr_reader :export_settings, :query, :id, :caption, :label

      def initialize(
        export_settings, id, caption,
        label = I18n.t(:"queries.configure_view.columns.input_label"),
        required: true,
        excluded_columns: [],
        allow_relation_columns: false
      )
        super()

        @export_settings = export_settings
        @query = @export_settings.query
        @id = id
        @caption = caption
        @label = label
        @required = required
        @excluded_columns = excluded_columns.map(&:to_s)
        @allow_relation_columns = allow_relation_columns
      end

      def available_columns
        @available_columns = query
                               .displayable_columns
                               .reject { |column| excluded_column?(column) }
                               .sort_by(&:caption)
                               .map { |column| { id: column.name.to_s, name: column.caption } }
      end

      def protected_options
        []
      end

      def selected_columns
        return columns_from_saved_export_settings if export_settings.settings.key?(:columns)

        query
          .columns
          .reject { |column| excluded_column?(column) }
          .map { |column| { id: column.name.to_s, name: column.caption } }
      end

      def excluded_column?(column)
        @excluded_columns.include?(column.name.to_s) ||
          (!@allow_relation_columns && column.is_a?(Queries::WorkPackages::Selects::RelationSelect))
      end

      private

      def columns_from_saved_export_settings
        saved_cols = export_settings.settings[:columns]
        # Restore the saved columns, retaining the saved order
        saved_cols.filter_map do |col|
          available_columns.find { |c| c[:id] == col }
        end
      end
    end
  end
end
