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

module Exports::PDF::Components::WpTableStyles
  def wp_table_group_header
    resolve_font(@styles.dig(:wp_table, :group_heading))
  end

  def wp_tables_margins
    resolve_margin(@styles.dig(:wp_table, :margins))
  end

  def wp_table_group_header_margins
    resolve_margin(@styles.dig(:wp_table, :group_heading))
  end

  def wp_table_margins
    resolve_margin(@styles.dig(:wp_table, :table))
  end

  def wp_table_cell
    resolve_table_cell(@styles.dig(:wp_table, :table, :cell))
  end

  def wp_table_header_cell
    wp_table_cell.merge(
      resolve_table_cell(@styles.dig(:wp_table, :table, :cell_header))
    )
  end

  def wp_table_sums_cell
    wp_table_cell.merge(
      resolve_table_cell(@styles.dig(:wp_table, :table, :cell_sums))
    )
  end

  def wp_table_subject_indent
    resolve_pt(@styles.dig(:wp_table, :table, :subject_indent), 0)
  end
end
