#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkPackage::PdfExport::WorkPackageListToPdf
  include Redmine::I18n
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper
  include CustomFieldsHelper
  include ToPdfHelper

  attr_accessor :work_packages,
                :pdf,
                :project,
                :query,
                :results,
                :options

  def initialize(work_packages, project, query, results, options = {})
    self.work_packages = work_packages
    self.project = project
    self.query = query
    self.results = results
    self.options = options

    self.pdf = get_pdf(current_language)
  end

  def to_pdf
    pdf.alias_nb_pages
    pdf.SetAutoPageBreak(false)
    pdf.footer_date = format_date(Date.today)

    pdf.AddPage('L')

    write_title

    write_headers

    write_rows

    write_tbc

    pdf.Output
  end

  private

  def write_title
    title = query.new_record? ? l(:label_work_package_plural) : query.name
    title = "#{project} - #{title}" if project
    pdf.SetTitle(title)

    pdf.SetFontStyle('B', 11)
    pdf.RDMCell(190, 10, title)
    pdf.Ln
  end

  def write_headers
    # headers
    pdf.SetFontStyle('B', 8)
    pdf.SetFillColor(230, 230, 230)
    column_contents = query.columns.map(&:caption)

    max_height = calculate_max_height(column_contents, col_width)

    pdf.RDMCell Page.table_width, max_height, '', 1, 1, 'L', 1
    pdf.SetXY(base_x, base_y)

    write_cells(column_contents, col_width, Page.row_height)
    draw_borders(base_x, base_y, base_y + max_height, col_width)

    pdf.SetY(base_y + max_height)
  end

  def write_rows
    # rows
    pdf.SetFontStyle('', 8)
    pdf.SetFillColor(255, 255, 255)
    previous_group = false
    work_packages.each do |work_package|
      if query.grouped? && (group = query.group_by_column.value(work_package)) != previous_group
        pdf.SetFontStyle('B', 9)
        pdf.RDMCell(277, Page.row_height,
                    (group.blank? ? 'None' : group.to_s) + " (#{results.work_package_count_for(group)})",
                    1, 1, 'L')
        pdf.SetFontStyle('', 8)
        previous_group = group
      end

      # fetch all the row values
      col_values = query.columns.map { |column|
        s = if column.is_a?(QueryCustomFieldColumn)
              cv = work_package.custom_values.detect { |v| v.custom_field_id == column.custom_field.id }
              show_value(cv)
            else
              value = work_package.send(column.name)
              if value.is_a?(Date)
                format_date(value)
              elsif value.is_a?(Time)
                format_time(value)
              else
                value
              end
            end
        s.to_s
      }

      max_height = calculate_max_height(column_contents, col_width)
      description_height = if options[:show_descriptions]
                             calculate_max_height([work_package.description.to_s],
                                                  [Page.table_width / 2])
                           else
                             0
                           end

      # make new page if it doesn't fit on the current one
      space_left = Page.height - base_y - Page.bottom_margin
      if max_height + description_height > space_left
        pdf.AddPage('L')
        base_x = pdf.GetX
        base_y = pdf.GetY
      end

      # write the cells on page
      write_cells(col_values, col_width, Page.row_height)
      draw_borders(base_x, base_y, base_y + max_height, col_width)

      # description
      if options[:show_descriptions]
        pdf.SetXY(base_x, base_y + max_height)
        write_cells([work_package.description.to_s],
                    [Page.table_width / 2],
                    Page.row_height)
        draw_borders(base_x,
                     base_y + max_height,
                     base_y + max_height + description_height,
                     [Page.table_width])
        pdf.SetY(base_y + max_height + description_height)
      else
        pdf.SetY(base_y + max_height)
      end
    end
  end

  def write_tbc
    if work_packages.size == Setting.work_packages_export_limit.to_i
      pdf.SetFontStyle('B', 10)
      pdf.RDMCell(0, Page.row_height, '...')
    end
  end

  def col_width
    @col_width ||= begin
      if query.columns.empty?
        []
      else
        col_width = query.columns.map { |c|
          if c.name == :subject ||
             (c.is_a?(QueryCustomFieldColumn) &&
              ['string', 'text'].include?(c.custom_field.field_format))
            4.0
          else
            1.0
          end
        }
        ratio = Page.table_width / col_width.reduce(:+)

        col_width.map { |w| w * ratio }
      end
    end
  end

  # Renders MultiCells and returns the maximum height used
  def write_cells(col_values, col_widths, row_height)
    base_y = pdf.get_y
    max_height = row_height
    col_values.each_with_index do |_column, i|
      col_x = pdf.get_x
      pdf.RDMMultiCell(col_widths[i], row_height, col_values[i], 'T', 'L', 1)
      max_height = (pdf.get_y - base_y) if (pdf.get_y - base_y) > max_height
      pdf.SetXY(col_x + col_widths[i], base_y)
    end
    max_height
  end

  # Draw lines to close the row (MultiCell border drawing in not uniform)
  def draw_borders(top_x, top_y, lower_y, col_widths)
    col_x = top_x
    pdf.Line(col_x, top_y, col_x, lower_y)    # id right border
    col_widths.each do |width|
      col_x += width
      pdf.Line(col_x, top_y, col_x, lower_y)  # columns right border
    end
    pdf.Line(top_x, top_y, top_x, lower_y)    # left border
    pdf.Line(top_x, lower_y, col_x, lower_y)  # bottom border
  end

  def calculate_max_height(column_contents, col_widths)
    # render it off-page to find the max height used
    base_x = pdf.GetX
    base_y = pdf.GetY
    pdf.SetY(2 * Page.height)
    max_height = write_cells(column_contents, col_widths, Page.row_height)
    pdf.SetXY(base_x, base_y)

    max_height
  end

  class Page
    # Landscape A4 = 210 x 297 mm
    def self.height
      210
    end

    def self.width
      297
    end

    def self.right_margin
      10
    end

    def self.bottom_margin
      20
    end

    def self.row_height
      5
    end

    def self.table_width
      width - right_margin - 10  # fixed left margin
    end
  end
end
