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
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackage::PDFExport::Common
  include Redmine::I18n
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper
  include CustomFieldsHelper
  include OpenProject::TextFormatting

  private

  def get_pdf(_language)
    ::WorkPackage::PDFExport::View.new(current_language)
  end

  def field_value(work_package, attribute)
    value = work_package.send(attribute)

    case value
    when Date
      format_date value
    when Time
      format_time value
    else
      value.to_s
    end
  end

  def success(content)
    ::Exports::Result
      .new format: :csv,
           title: title,
           content: content,
           mime_type: 'application/pdf'
  end

  def error(message)
    raise ::Exports::ExportError.new message
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

  def current_y_position
    OpenStruct.new y: pdf.y, page: pdf.page_number
  end

  def position_diff(position_a, position_b)
    position_a.y - position_b.y + (position_b.page - position_a.page) * pdf.bounds.height
  end
end
