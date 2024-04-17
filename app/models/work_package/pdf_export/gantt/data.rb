#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

# Utility classes for Gantt chart generation

class GanttPageGroup
  attr_accessor :index, :pages

  def initialize(index, work_packages, pages)
    @index = index
    @pages = pages
    @work_packages = work_packages
    @pages.each { |page| page.group = self }
  end
end

class GanttPage
  attr_accessor :index, :rows, :columns, :lines, :text_column, :width, :height, :header_cells, :header_row_height, :group

  def initialize(index, work_packages, header_cells, rows, columns, text_column, width, height, header_row_height)
    @index = index
    @rows = rows
    @columns = columns
    @work_packages = work_packages
    @text_column = text_column
    @width = width
    @height = height
    @header_cells = header_cells
    @header_row_height = header_row_height
    @lines = []
    @group = nil
    rows.each { |row| row.page = self }
    columns.each { |column| column.page = self }
  end

  def add_line(left, right, top, bottom)
    @lines.push({ left:, right:, top:, bottom: })
  end

  def add_lines(lines)
    lines.each { |line| add_line(line[0], line[1], line[2], line[3]) }
  end
end

class GanttRow
  attr_accessor :index, :page, :work_package, :shape, :top, :left, :height, :bottom

  def initialize(index, work_package, shape, left, top, height)
    @index = index
    @work_package = work_package
    @shape = shape
    @top = top
    @left = left
    @height = height
    @bottom = top + height
    @page = nil
  end
end

class GanttColumn
  attr_accessor :date, :left, :right, :width, :work_packages, :page

  def initialize(date, left, width, work_packages)
    @date = date
    @left = left
    @right = left + width
    @width = width
    @work_packages = work_packages
    @page = nil
  end
end

class GanttLineInfo
  attr_accessor :page_group, :rows, :start_row, :start_left, :start_top, :finish_row, :finish_left, :finish_top

  def initialize(page_group, rows, start_row, finish_row)
    @page_group = page_group
    @rows = rows
    @start_row = start_row
    @finish_row = finish_row
    init_positions
  end

  def init_positions
    @start_left = @start_row.shape.left
    @start_top = @start_row.shape.top + (@start_row.shape.height / 2)
    @finish_left = @finish_row.shape.right
    @finish_top = @finish_row.shape.top + (@finish_row.shape.height / 2)
  end
end

class GanttHeaderCell
  attr_accessor :text, :left, :right, :top, :bottom, :height, :width

  def initialize(text, left, right, top, bottom)
    @text = text
    @left = left
    @right = right
    @top = top
    @bottom = bottom
    @height = bottom - top
    @width = right - left
  end
end

class GanttTextColumn
  attr_accessor :title, :width, :left, :right, :top, :height, :bottom, :padding_h, :padding_v

  def initialize(title, left, width, top, height, padding_h, padding_v)
    @title = title
    @width = width
    @left = left
    @right = left + width
    @padding_h = padding_h
    @padding_v = padding_v
    @top = top
    @height = height
    @bottom = top + height
  end
end

class GanttShape
  attr_accessor :type, :left, :right, :top, :bottom, :width, :height, :work_package, :columns, :color

  def initialize(type, left, width, top, height, work_package, columns, color)
    @type = type
    @left = left
    @right = left + width
    @top = top
    @bottom = top + height
    @width = width
    @height = height
    @work_package = work_package
    @columns = columns
    @color = color
  end
end

class GanttLineFragment
  attr_accessor :left, :right, :top, :bottom

  def initialize(left, right, top, bottom)
    @left = left
    @right = right
    @top = top
    @bottom = bottom
  end
end
