# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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

class Projects::ColumnHeaderComponent < Tables::ColumnHeaderComponent
  def column_caption
    if lft_column?(column)
      helpers.op_icon("icon-hierarchy")
    elsif favored_column?(column)
      render(Primer::Beta::Octicon.new(icon: "star-fill", color: :subtle, ml: 2, "aria-label": I18n.t(:label_favorite)))
    else
      super
    end
  end

  def sort_class(column)
    order = order_string(column)

    order.nil? ? nil : "sort #{order}"
  end

  def header_options(column)
    options = super

    if lft_column?(column)
      options[:id] = "project-table--hierarchy-header"
    end

    options
  end

  def sort_header_outer_classes(column)
    if lft_column?(column)
      "generic-table--sort-header-outer_no-highlighting"
    elsif favored_column?(column)
      "generic-table--header_centered generic-table--header_no-min-width"
    else
      super
    end
  end

  def sort_link_title(column)
    if lft_column?(column)
      t(:label_sort_by, value: %("#{t(:label_project_hierarchy)}"))
    else
      super
    end
  end

  def sortable_column?(column)
    (lft_column?(column) && !sorted_by_lft?) ||
      (!lft_column?(column) && super)
  end

  def sorted_by_lft?
    first_order_by&.attribute == :lft
  end

  def lft_column?(column)
    column.attribute == :lft
  end

  def favored_column?(column)
    column.attribute == :favored
  end
end
