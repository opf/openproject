#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'mini_magick'

module WorkPackage::PDFExport::Attachments
  def resize_image(file_path)
    resized_file_path = extend_file_name_in_path(file_path, '__x325')
    image = MiniMagick::Image.open(file_path)
    image.resize("x325>")
    image.write(resized_file_path)

    @resized_image_paths << resized_file_path

    resized_file_path
  end

  def extend_file_name_in_path(file_path, name_suffix)
    dir_path = File.dirname(file_path)
    file_extension = File.extname(file_path)
    file_name = File.basename(file_path, '.*')

    File.join(dir_path, "#{file_name}#{name_suffix}#{file_extension}")
  end

  def pdf_embeddable?(content_type)
    %w[image/jpeg image/png].include?(content_type)
  end

  def delete_all_resized_images
    @resized_image_paths.each do |file_path|
      File.delete(file_path)
    end
  end
end
