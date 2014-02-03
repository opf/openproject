#-- copyright
# OpenProject PDF Export Plugin
#
# Copyright (C)2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject PDF Export Plugin is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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
# See doc/COPYRIGHT.md for more details.
#++

module OpenProject::PdfExport::ExportCard
  class CardElement
    include OpenProject::PdfExport::Exceptions

    def initialize(pdf, orientation, groups_config, work_package)
      @pdf = pdf
      @orientation = orientation
      @groups_config = groups_config
      @work_package = work_package
      @group_elements = []

      # raise BadlyFormedExportCardConfigurationError.new("Badly formed YAML") if @rows.nil?

      # Simpler to remove empty rows before calculating the row sizes
      RowElement.prune_empty_groups(@groups_config, work_package)

      # Get an array of all the row hashes
      rows = []
      @groups_config.each do |gk, gv|
        gv["rows"].each do |rk, rv|
          rows << rv
        end
      end

      # Assign the row height, ignoring groups
      heights = assign_row_heights(rows)

      text_padding = @orientation[:text_padding]
      group_padding = @orientation[:group_padding]
      current_row = 0
      current_y_offset = text_padding

      # Initialize groups
      @groups_config.each_with_index do |(g_key, g_value), i|
        row_count = g_value["rows"].count
        row_heights = heights.slice(current_row, row_count)
        group_height = row_heights.sum
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

    def assign_row_heights(rows)
      # Assign initial heights for rows in all groups
      available = @orientation[:height] - @orientation[:text_padding]
      c = rows.count
      assigned_heights = Array.new(c){ available / c }

      min_heights = min_row_heights(rows)
      diffs = assigned_heights.zip(min_heights).map {|a, m| a - m}
      diffs.each_with_index do |diff, i|
        if diff < 0
          # Need to grab some pixels from a low priority row and add them to current one
          reduce_low_priority_rows(rows, assigned_heights, diffs, i)
        end
      end

      # TODO: Check assigned heights are big enough
      assigned_heights
    end

    def reduce_low_priority_rows(rows, assigned_heights, diffs, conflicted_i)
      # Get an array of row indexes sorted by inverse priority
      priorities = *(0..rows.count - 1)
        .zip(rows.map { |row| row["priority"] or 10 })
        .sort {|x,y| y[1] <=> x[1]}
        .map {|x| x[0]}

      to_reduce = diffs[conflicted_i] * -1
      priorities.each do |p|
        diff = diffs[p]
        if diff > 0
          if diff >= to_reduce
            exchange(assigned_heights, diffs, p, conflicted_i, to_reduce)
            return true
          else
            exchange(assigned_heights, diffs, p, conflicted_i, diff)
            to_reduce -= diff
          end
        end
      end
      return false
    end

    def exchange(heights, diffs, a, b, v)
      heights[a] -= v
      heights[b] += v
      diffs[a] -= v
      diffs[b] += v
    end

    def min_row_heights(rows)
      # Calculate minimum user assigned heights...
      min_heights = Array.new(rows.count)
      rows.each_with_index do |row, i|
        min_heights[i] = min_row_height(row)
      end
      min_heights
    end

    def min_row_height(row)
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