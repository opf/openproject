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

# How this works:
# The Gantt chart PDF export is built up of several components:
# - GanttBuilder: This is the main class that builds the Gantt chart.
#                 It is responsible for creating the pages, columns, rows, and shapes.
#   - GanttBuilderMonths: This class is a subclass of GanttBuilder and is responsible for
#                         building the Gantt chart with months as the zoom level.
#   - GanttBuilderDays: This class is a subclass of GanttBuilder and is responsible for
#                       building the Gantt chart with days as the zoom level.
#   - GanttBuilderQuarters: This class is a subclass of GanttBuilder and is responsible for
#                           building the Gantt chart with quarters as the zoom level.
# - GanttPainter: This class is responsible for painting the Gantt chart.
#                 It paints the grid, header row, lines, bars, milestones, and rows.
# - Data classes: These classes are used to store the data that is used to build the Gantt chart.
#
# 1. Build the data classes, do the layout, measuring, etc.
# 2. Paint the Gantt chart into the PDF

module WorkPackage::PDFExport::Gantt
  GANTT_DAY_COLUMN_WIDTHS = [64, 32, 24, 18].freeze
  GANTT_COLUMN_WIDTHS = [128, 64, 32, 24].freeze
  GANTT_COLUMN_WIDTHS_NAMES = %w[very_wide wide medium narrow].freeze
  GANTT_MODE_NAMES = %w[day week month quarter].freeze
  GANTT_MODE_DEFAULT = "day".freeze
  GANTT_COLUMN_DEFAULT = "wide".freeze

  def write_work_packages_gantt!(work_packages, id_wp_meta_map)
    wps = work_packages.select { |work_package| work_package.start_date || work_package.due_date }
    return if wps.empty?

    mode = gantt_settings_mode
    column_width = gantt_settings_column_width(mode)
    write_gantt(mode, column_width, id_wp_meta_map, wps)
  end

  private

  def gantt_settings_mode
    mode = options[:gantt_mode] || GANTT_MODE_DEFAULT
    mode = GANTT_MODE_DEFAULT if GANTT_MODE_NAMES.exclude?(mode)
    mode.to_sym
  end

  def gantt_settings_column_width(mode)
    width_index = GANTT_COLUMN_WIDTHS_NAMES.find_index(options[:gantt_width] || GANTT_COLUMN_DEFAULT)
    width_index = GANTT_COLUMN_WIDTHS_NAMES.find_index(GANTT_COLUMN_DEFAULT) if width_index.nil?
    mode == :day ? GANTT_DAY_COLUMN_WIDTHS[width_index] : GANTT_COLUMN_WIDTHS[width_index]
  end

  def gantt_builder(mode, column_width)
    case mode
    when :week
      GanttBuilderWeeks.new(pdf, heading, column_width)
    when :month
      GanttBuilderMonths.new(pdf, heading, column_width)
    when :quarter
      GanttBuilderQuarters.new(pdf, heading, column_width)
    else
      # when :day
      GanttBuilderDays.new(pdf, heading, column_width)
    end
  end

  def write_gantt(mode, column_width, id_wp_meta_map, work_packages)
    builder = gantt_builder(mode, column_width)
    pages = builder.build(work_packages, id_wp_meta_map, query)
    pages = pages.filter { |page| page.columns.pluck(:work_packages).flatten.any? } if options[:filter_empty]
    painter = GanttPainter.new(pdf)
    painter.paint(pages)
  end

  GanttDataPageGroup = Struct.new(:index, :entry_ids, :pages) do
    def initialize(*args)
      super
      pages.each { |page| page.group = self }
    end
  end

  GanttDataPage = Struct.new(:index, :entry_ids, :header_cells, :rows, :columns,
                             :text_column, :width, :height, :header_row_height, :group, :lines) do
    def initialize(*args)
      super
      rows.each { |row| row.page = self }
      columns.each { |column| column.page = self }
      self.lines = []
    end

    def add_line(left, right, top, bottom)
      lines.push({ left:, right:, top:, bottom: })
    end

    def add_lines(new_lines)
      new_lines.each { |line| add_line(line[0], line[1], line[2], line[3]) }
    end
  end

  GanttDataText = Data.define(:text, :left, :right, :top, :bottom, :font_size) do
    def height = bottom - top

    def width = right - left
  end

  GanttDataRow = Struct.new(:index, :entry_id, :shape, :text_lines, :left, :top, :height, :page) do
    def bottom = top + height
  end

  GanttDataColumn = Struct.new(:date, :left, :width, :entry_ids, :page) do
    def right = left + width
  end

  GanttDataLineInfo = Data.define(:page_group, :rows, :start_row, :finish_row) do
    def start_left = start_row.shape.left

    def start_top = start_row.shape.top + (start_row.shape.height / 2)

    def finish_left = finish_row.shape.right

    def finish_top = finish_row.shape.top + (finish_row.shape.height / 2)
  end

  GanttDataHeaderCell = Data.define(:text, :left, :right, :top, :bottom) do
    def height = bottom - top

    def width = right - left
  end

  GanttDataTextColumn = Data.define(:title, :left, :width, :top, :height, :padding_h, :padding_v) do
    def right = left + width

    def bottom = top + height
  end

  GanttDataEntry = Data.define(:id, :subject, :work_package) do
    def group? = work_package.nil?
  end

  GanttDataShape = Data.define(:type, :left, :width, :top, :height, :entry_id, :columns, :color) do
    def right = left + width

    def bottom = top + height
  end
end
