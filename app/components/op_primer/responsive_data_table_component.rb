# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) The OpenProject GmbH
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

module OpPrimer
  # Compatibility façade letting a +BorderBoxTableComponent+ subclass render
  # through +Primer::OpenProject::DataTable+ by changing its superclass.
  #
  # Keeps the BorderBox defaults its callers rely on: not sortable, no actions
  # column unless asked for, a required mobile title, and a blank slate rather
  # than a one-line empty message.
  class ResponsiveDataTableComponent < OpPrimer::BorderBoxTableComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
    include DataTableRendering

    def data_table_title
      mobile_title
    end

    def empty_state_arguments
      arguments = { title: blank_title, description: blank_description }
      arguments[:icon] = blank_icon if blank_icon
      arguments
    end

    def cell_classes_for(column)
      static = class_names(
        "op-data-table--no-mobile": mobile_columns.exclude?(column),
        "op-data-table--main-column": main_column?(column)
      )

      ->(row) { class_names(static, row_class.new(row: row, table: self).column_css_class(column)) }
    end

    def data_table_classes
      "op-data-table--responsive"
    end

    def data_table_footer
      return unless has_footer?

      footer
    end
  end
end
