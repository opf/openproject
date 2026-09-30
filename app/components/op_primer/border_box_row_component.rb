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

module OpPrimer
  class BorderBoxRowComponent < RowComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
    include ComponentHelpers

    def mobile_label(column)
      return unless table.mobile_labels.include?(column)

      table.column_title(column)
    end

    def visible_on_mobile?(column)
      table.mobile_columns.include?(column)
    end

    def cell_classes(column)
      class_names(
        "op-border-box-grid__row-item",
        column_css_class(column),
        {
          "op-border-box-grid__row-item--main-column": table.main_column?(column),
          ellipsis: !table.main_column?(column),
          "op-border-box-grid__row-item--no-mobile": !visible_on_mobile?(column)
        }
      )
    end

    def cell_role(column, colindex)
      table.main_column?(column) && colindex.zero? ? :rowheader : :cell
    end

    def checkmark(condition)
      if condition
        render(Primer::Beta::Octicon.new(icon: :check))
      end
    end
  end
end
