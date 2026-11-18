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

module Exports::PDF::Components::Gantt
  class GanttTextColumnLayout
    TEXT_AREA_MAX_RATIO = 0.6
    MAX_WIDTHS = { subject: 200.0, simple_text: 120.0, fixed: 80.0 }.freeze
    MIN_COLUMN_WIDTH = 30.0
    PADDING_H = 3.0
    # Prawn's line wrapping needs a little room beyond the measured width, or exact fits wrap
    MEASURE_SLACK = 1.0
    CELL_FONT_SIZE = 8
    HEADER_FONT_SIZE = 9
    STRETCHABLE_KINDS = %i[subject simple_text].freeze

    LayoutColumn = Struct.new(:column, :caption, :kind, :width, :left) do
      def right = left + width
    end

    attr_reader :columns

    def initialize(pdf, query, query_columns, cell_value:, max_area_ratio: TEXT_AREA_MAX_RATIO)
      @pdf = pdf
      @cell_value = cell_value
      @max_area_ratio = max_area_ratio
      @values = {}
      text_columns = TextColumns.new(query)
      @columns = query_columns.map do |column|
        LayoutColumn.new(column, column.caption, text_columns.kind(column) || :simple_text, 0.0, 0.0)
      end
    end

    def measure(work_packages)
      @natural_widths = columns.map { |column| natural_width(column, work_packages) }
      self
    end

    def fit(page_width, date_column_width)
      columns.zip(@natural_widths).each { |column, width| column.width = width }
      shrink_to(max_area(page_width, date_column_width))
      update_lefts
    end

    def stretch(extra_width)
      target = columns.find { |column| stretchable?(column) }
      return false if target.nil?

      target.width += extra_width
      update_lefts
      true
    end

    def total_width
      columns.sum(&:width)
    end

    def value(work_package, column)
      @values[[work_package.id, column.name]] ||= @cell_value.call(work_package, column).to_s
    end

    private

    def natural_width(layout_column, work_packages)
      max_width = MAX_WIDTHS.fetch(layout_column.kind)
      width = header_width(layout_column.caption)
      work_packages.each do |work_package|
        break if width >= max_width

        width = [width, cell_width(value(work_package, layout_column.column))].max
      end
      width.clamp(MIN_COLUMN_WIDTH, max_width)
    end

    def header_width(caption)
      full_width = @pdf.width_of(caption, size: HEADER_FONT_SIZE, style: :bold)
      widest_word = caption.split.map { |word| @pdf.width_of(word, size: HEADER_FONT_SIZE, style: :bold) }.max || 0
      [full_width / 2, widest_word].max + (PADDING_H * 2) + MEASURE_SLACK
    end

    def cell_width(text)
      @pdf.width_of(text, size: CELL_FONT_SIZE) + (PADDING_H * 2) + MEASURE_SLACK
    end

    def stretchable?(layout_column)
      STRETCHABLE_KINDS.include?(layout_column.kind)
    end

    def max_area(page_width, date_column_width)
      [page_width * @max_area_ratio, page_width - date_column_width].min
    end

    def shrink_to(max_area)
      excess = total_width - max_area
      stretchable, fixed = columns.partition { |column| stretchable?(column) }
      excess = shrink(stretchable, excess) if excess.positive?
      shrink(fixed, excess) if excess.positive?
    end

    def shrink(layout_columns, excess)
      shrinkable = layout_columns.sum { |column| column.width - MIN_COLUMN_WIDTH }
      return excess unless shrinkable.positive?

      ratio = [excess / shrinkable, 1.0].min
      layout_columns.each { |column| column.width -= (column.width - MIN_COLUMN_WIDTH) * ratio }
      excess - (shrinkable * ratio)
    end

    def update_lefts
      columns.inject(0.0) do |left, column|
        column.left = left
        left + column.width
      end
    end
  end
end
