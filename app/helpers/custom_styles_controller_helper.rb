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

module CustomStylesControllerHelper
  MAX_FONT_UPLOAD_SIZE = 30.megabytes

  def validate_font_uploads(custom_style_params)
    %i(export_font_regular export_font_bold export_font_italic export_font_bold_italic).each do |name|
      if custom_style_params[name].is_a?(ActionDispatch::Http::UploadedFile)
        error = validate_font_file(name, custom_style_params[name].tempfile)
        return error if error
      end
    end
    nil
  end

  private

  def validate_font_file(name, filename)
    error = validate_font_file_size(name, filename)
    error ||= validate_font_file_format(name, filename)
    error
  end

  def validate_font_file_format(name, filename)
    "#{name.to_s.humanize} #{I18n.t('admin.custom_styles.fonts.file_is_invalid')}" unless valid_ttf?(filename)
  end

  def font_file_size(filename)
    File.size(filename).to_i
  end

  def validate_font_file_size(name, filename)
    size = font_file_size(filename)
    if size >= MAX_FONT_UPLOAD_SIZE
      "#{name.to_s.humanize} #{I18n.t('admin.custom_styles.fonts.file_too_large',
                                      count: (MAX_FONT_UPLOAD_SIZE / 1.megabyte).to_i)}"
    end
  end

  def valid_ttf?(filename)
    file = TTFunk::File.open(filename)
    file.name.font_name.present?
  rescue StandardError
    false
  end
end
