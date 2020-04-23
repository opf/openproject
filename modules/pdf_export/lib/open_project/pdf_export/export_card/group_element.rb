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
  class GroupElement
    include OpenProject::PDFExport::Exceptions

    def initialize(pdf, orientation, config, work_package)
      @pdf = pdf
      @orientation = orientation
      @config = config
      @rows_config = config["rows"]
      @work_package = work_package
      @row_elements = []

      current_y_offset = 0
      row_heights = @orientation[:row_heights]

      @rows_config.each_with_index do |(r_key, r_value), i|
        current_y_offset += (row_heights[i - 1]) if i > 0
        row_orientation = {
          y_offset: @orientation[:height] - current_y_offset,
          x_offset: 0,
          width: @orientation[:width] - (@orientation[:group_padding] * 2),
          height: row_heights[i],
          text_padding: @orientation[:text_padding]
        }

        @row_elements << RowElement.new(@pdf, row_orientation, r_value, @work_package)
      end
    end

    def draw
      padding = @orientation[:group_padding]
      top_left = [@orientation[:x_offset] + padding, @orientation[:y_offset]]
      bounds = @orientation.slice(:width, :height)
      bounds[:width] -= padding * 2

      @pdf.bounding_box(top_left, bounds) do
        @pdf.stroke_color '000000'

        # Draw rows
        @row_elements.each do |row|
          row.draw
        end

        if (@config["has_border"] or false)
          @pdf.stroke_bounds
        end
      end

    end
  end
end
