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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackage::PDFExport::Common::AttributesTableStyles
  def wp_attributes_group_label_margins
    resolve_margin(@styles.dig(:work_package, :attributes_group))
  end

  def wp_attributes_group_label
    resolve_font(@styles.dig(:work_package, :attributes_group))
  end

  def wp_attributes_group_label_hr
    {
      color: @styles.dig(:work_package, :attributes_group, :hr, :color),
      height: resolve_pt(@styles.dig(:work_package, :attributes_group, :hr, :height), 1)
    }
  end

  def markdown_field_label_margins
    resolve_margin(@styles.dig(:work_package, :attributes_group))
  end

  def wp_attributes_subject
    resolve_font(@styles.dig(:work_package, :subject))
  end

  def wp_attributes_subject_margins
    resolve_margin(@styles.dig(:work_package, :subject))
  end

  def wp_attributes_table_margins
    resolve_margin(@styles.dig(:work_package, :attributes_table))
  end

  def wp_attributes_table_cell
    resolve_table_cell(@styles.dig(:work_package, :attributes_table, :cell))
  end

  def wp_attributes_table_label
    resolve_font(@styles.dig(:work_package, :attributes_table, :cell_label))
  end

  def wp_attributes_table_label_cell
    wp_attributes_table_cell.merge(
      resolve_table_cell(@styles.dig(:work_package, :attributes_table, :cell_label))
    )
  end
end
