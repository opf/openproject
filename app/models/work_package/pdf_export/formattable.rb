#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module WorkPackage::PDFExport::Formattable
  ##
  # Writes the formatted work package description into the document.
  #
  # A border (without one on the top) is painted around the area painted by the description.
  #
  # @param work_package [WorkPackage] The work package for which the description is to be printed.
  # @param markdown [string] The formattable text
  # @param label [string|null] The label to print, if any
  def write_formattable!(work_package, markdown:, label: WorkPackage.human_attribute_name(attribute))
    height = write_formattable_content(work_package, markdown: markdown, label: label)

    data = make_formattable_label_row(label) +
           make_formattable_border_rows(height, label)

    pdf.table(data, column_widths: column_widths)
  end

  def write_formattable_content(work_package, markdown:, label: true)
    float_with_height_indicator do
      pdf.move_down(cell_padding[1])

      pdf.indent(formattable_padding_left(label), cell_padding[3]) do
        pdf.markup format_text(markdown, object: work_package, format: :html)
      end
    end
  end

  def float_with_height_indicator
    former_position = new_position = current_y_position

    pdf.float do
      yield

      new_position = current_y_position
    end

    position_diff(former_position, new_position)
  end

  def make_formattable_label_row(label)
    if label.present?
      [[make_formattable_label(label), pdf.make_cell('', borders: [:right], colspan: formattable_colspan)].compact]
    else
      [[pdf.make_cell('', borders: %i[right left], colspan: formattable_colspan)]]
    end
  end

  def formattable_padding_left(label)
    if label.present?
      column_widths.first + cell_padding[1]
    else
      cell_padding[1]
    end
  end

  def formattable_padding_right
    cell_padding[3]
  end

  def make_formattable_border_rows(height, label)
    border_row_height = 10

    (height / border_row_height).ceil.times.map do |index|
      make_formattable_border_row(border_row_height,
                                  label,
                                  index == (height / border_row_height).ceil - 1)
    end
  end

  def make_formattable_border_row(border_row_height, label, last)
    border_left = if label
                    [:left]
                  else
                    %i[left right]
                  end

    border_right = [:right]

    if last
      border_left << :bottom
      border_right << :bottom
    end

    if label
      [pdf.make_cell('', height: border_row_height, borders: border_left, colspan: 1),
       pdf.make_cell('', height: border_row_height, borders: border_right, colspan: formattable_colspan)]
    else
      [pdf.make_cell('', height: border_row_height, borders: border_left, colspan: formattable_colspan)]
    end
  end

  def make_formattable_label(label)
    pdf.make_cell("#{label}:", borders: [:left], font_style: :bold, padding: cell_padding)
  end

  def formattable_colspan
    raise NotImplementedError, 'to be implemented where included'
  end
end
