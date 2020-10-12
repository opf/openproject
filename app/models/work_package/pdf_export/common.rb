#-- encoding: UTF-8

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

module WorkPackage::PDFExport::Common
  include Redmine::I18n
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper
  include CustomFieldsHelper
  include WorkPackage::PDFExport::ToPdfHelper
  include OpenProject::TextFormatting

  private

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
    WorkPackage::Exporter::Result::Success
      .new format: :csv,
           title: title,
           content: content,
           mime_type: 'application/pdf'
  end

  def error(message)
    WorkPackage::Exporter::Result::Error.new message
  end

  def cell_padding
    @cell_padding ||= [2, 5, 2, 5]
  end

  def configure_markup
    # Do not attempt to fetch images.
    # Fetching images can cause errors e.g. a 403 is returned when attempting to fetch from aws with
    # a no longer valid token.
    # Such an error would cause the whole export to error.
    pdf.markup_options = {
      image: {
        loader: ->(_src) { nil },
        placeholder: "<i>[#{I18n.t('export.image.omitted')}]</i>"
      }
    }
  end

  ##
  # Writes the formatted work package description into the document.
  #
  # A border (without one on the top) is painted around the area painted by the description.
  #
  # @param work_package [WorkPackage] The work package for which the description is to be printed.
  # @param label [boolean] Whether a label is to be printed in a column preceding the description.
  def write_description!(work_package, label = true)
    height = write_description_html!(work_package, label)

    data = make_description_label_row(label) +
           make_description_border_rows(height, label)

    pdf.table(data, column_widths: column_widths)
  end

  def write_description_html!(work_package, label)
    float_with_height_indicator do
      pdf.move_down(cell_padding[1])

      pdf.indent(description_padding_left(label), cell_padding[3]) do
        pdf.markup(formatted_description_text(work_package))
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

  def make_description_label_row(label)
    if label
      [[make_description_label, pdf.make_cell('', borders: [:right], colspan: description_colspan)].compact]
    else
      [[pdf.make_cell('', borders: %i[right left], colspan: description_colspan)]]
    end
  end

  def description_padding_left(label)
    if label
      column_widths.first + cell_padding[1]
    else
      cell_padding[1]
    end
  end

  def description_padding_right
    cell_padding[3]
  end

  def formatted_description_text(work_package)
    format_text(work_package.description.to_s, object: work_package, format: :html)
  end

  def make_description_border_rows(height, label)
    border_row_height = 10

    (height / border_row_height).ceil.times.map do |index|
      make_description_border_row(border_row_height,
                                  label,
                                  index == (height / border_row_height).ceil - 1)
    end
  end

  def make_description_border_row(border_row_height, label, last)
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
       pdf.make_cell('', height: border_row_height, borders: border_right, colspan: description_colspan)]
    else
      [pdf.make_cell('', height: border_row_height, borders: border_left, colspan: description_colspan)]
    end
  end

  def make_description_label
    text = WorkPackage.human_attribute_name(:description) + ':'
    pdf.make_cell(text, borders: [:left], font_style: :bold, padding: cell_padding)
  end

  def description_colspan
    raise NotImplementedError, 'to be implemented where included'
  end

  def current_y_position
    OpenStruct.new y: pdf.y, page: pdf.page_number
  end

  def position_diff(position_a, position_b)
    position_a.y - position_b.y + (position_b.page - position_a.page) * pdf.bounds.height
  end
end
