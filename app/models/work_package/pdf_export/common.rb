#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module WorkPackage::PdfExport::Common
  include Redmine::I18n
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper
  include CustomFieldsHelper
  include WorkPackage::PdfExport::ToPdfHelper

  def field_value(work_package, attribute)
    value = work_package.send(attribute)

    if value.is_a? Date
      format_date value
    elsif value.is_a? Time
      format_time value
    else
      value.to_s
    end
  end

  def success(content)
    WorkPackage::Exporter::Success
      .new format: :csv,
           title: title,
           content: content,
           mime_type: 'application/pdf'
  end

  def error(message)
    WorkPackage::Exporter::Error.new message
  end

  def cell_padding
    @cell_padding ||= [2, 5, 2, 5]
  end

  ##
  # Creates a number of cell rows to show the description.
  #
  # The description is split into many smaller cells so that
  # prawn-table does not go crazy with long texts causing
  # empty pages in between.
  #
  # The fact that prawn-table can't handle multi-page table cells
  # is a known, unsolved issue. Hence this workaround.
  #
  # @param description [String] The work package's description
  # @param options [Hash] Allows changing the number of lines per cell
  #                       through the :max_lines_per_cell option.
  # @return [Array] An array of rows to be added to the work packages table.
  def make_description(description, options = {})
    lines = description.lines
    max = options[:max_lines_per_cell] || max_lines_per_description_cell

    if lines.size > max_lines_per_description_cell
      cells = split_description lines, max: max, cell_options: Hash(options[:cell_options])

      format_description_segments!(cells)
    else
      [make_single_description(description, Hash(options[:cell_options]))]
    end
  end

  ##
  # Formats the cells so that they appear to be one big cell.
  def format_description_segments!(cells)
    cells.first.padding[0] = cell_padding[0] # top padding
    cells.last.padding[2] = cell_padding[2] # bottom padding
    cells.last.borders = [:left, :right, :bottom]
    cells
  end

  def split_description(lines, max: max_lines_per_description_cell, cell_options: {})
    head = make_description_segment lines.take(max).join, cell_options

    if lines.size > max
      [head] + split_description(lines.drop(max), max: max, cell_options: cell_options)
    else
      [head]
    end
  end

  def make_description_segment(description, options = {})
    cell_options = {
      borders: [:left, :right],
      padding: [0, cell_padding[1], 0, cell_padding[3]]
    }

    make_single_description description, cell_options.merge(options)
  end

  def make_single_description(description, options = {})
    cell_options = { colspan: description_colspan }

    pdf.make_cell description, cell_options.merge(options)
  end

  def max_lines_per_description_cell
    3
  end

  def description_colspan
    raise NotImplementedError, 'to be implemented where included'
  end
end
