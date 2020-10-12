#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::PDFExport::ExportCard
  class CardElement
    include OpenProject::PDFExport::Exceptions

    def initialize(pdf, orientation, groups_config, work_package)
      @pdf = pdf
      @orientation = orientation
      @groups_config = groups_config
      @work_package = work_package
      @group_elements = []

      # Simpler to remove empty rows before calculating the row sizes
      RowElement.prune_empty_groups(@groups_config, work_package)

      # NEW
      all_heights = assign_all_heights_new(@groups_config)
      reduce_rows(all_heights)

      text_padding = @orientation[:text_padding]
      group_padding = @orientation[:group_padding]
      current_row = 0
      current_y_offset = text_padding

      # Initialize groups
      @groups_config.each_with_index do |(g_key, g_value), i|
        row_count = g_value["rows"].count
        row_heights = all_heights[:row_heights].reject {|row| row[:group] != i}.map{|row| row[:height]}
        group_height = all_heights[:group_heights][i]
        group_orientation = {
          y_offset: @orientation[:height] - current_y_offset,
          x_offset: 0,
          width: @orientation[:width],
          height: group_height,
          row_heights: row_heights,
          text_padding: text_padding,
          group_padding: group_padding
        }
        @group_elements << GroupElement.new(@pdf, group_orientation, g_value, @work_package)

        current_y_offset += group_height
        current_row += row_count
      end
    end

    def assign_all_heights_new(groups)
      available = @orientation[:height] - (@orientation[:group_padding] * 2)
      group_heights = Array.new
      row_heights = Array.new

      groups.each_with_index do |(gk, gv), i|
        enforced_group_height = gv["height"] || -1
        used_group_height = 0

        gv["rows"].each do |rk, rv|
          # The + 1 on the height is needed as prawn does not seem to render
          # when the string to render has the same size as the row height.
          if rv["height"]
            used_group_height += rv["height"] + 1
            row_heights << { height: rv["height"] + 1, group: i, priority: rv["priority"] || 10 }
          else
            used_group_height += min_row_height(rv) + 1
            row_heights << { height: min_row_height(rv) + 1, group: i, priority: rv["priority"] || 10 }
          end
        end

        group_heights << [used_group_height, enforced_group_height].max
      end

      { group_heights: group_heights, row_heights: row_heights }
    end

    def reduce_rows(heights)
      available = @orientation[:height] - (@orientation[:group_padding] * 2)
      diff = available - heights[:group_heights].sum
      return false if diff >= 0
      diff *= -1

      rows = heights[:row_heights]
      groups = heights[:group_heights]

      priorities = *(0..rows.count - 1)
        .zip(rows.map { |row| row[:priority] or 10 })
        .sort {|x,y| y[1] <=> x[1]}
        .map {|x| x[0]}

      priorities.each do |p|
        to_reduce = rows[p]
        if to_reduce[:height] >= diff
          to_reduce[:height] -= diff
          groups[to_reduce[:group]] -= diff
          break
        else
          diff -= to_reduce[:height]
          groups[to_reduce[:group]] -= to_reduce[:height]
          to_reduce[:height] = 0
        end
      end

      heights
    end

    def min_row_height(row)
      return row["enforced_group_height"] if row["enforced_group_height"]

      # Look through each of the row's columns for the column with the largest minimum height
      largest = 0
      row["columns"].each do |rk, rv|
        min_lines = rv["minimum_lines"] || 1
        font_size = rv["min_font_size"] || rv["font_size"] || 10
        min_col_height = (@pdf.font.height_at(font_size) * min_lines).floor
        largest = min_col_height if min_col_height > largest
      end
      largest
    end

    def draw
      top_left = [@orientation[:x_offset], @orientation[:y_offset]]
      bounds = @orientation.slice(:width, :height)

      @pdf.bounding_box(top_left, bounds) do
        @pdf.stroke_color '000000'

        # Draw rows
        @group_elements.each do |group|
          group.draw
        end

        @pdf.stroke_bounds
      end

    end
  end
end
