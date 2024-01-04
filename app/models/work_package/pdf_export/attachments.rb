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

require 'mini_magick'

module WorkPackage::PDFExport::Attachments
  def resize_image(file_path)
    tmp_file = Tempfile.new(['temp_image', File.extname(file_path)])
    @resized_images = [] if @resized_images.nil?

    @resized_images << tmp_file
    resized_file_path = tmp_file.path

    image = MiniMagick::Image.open(file_path)
    image.resize("x800>")
    image.write(resized_file_path)

    resized_file_path
  end

  def pdf_embeddable?(content_type)
    %w[image/jpeg image/png].include?(content_type)
  end

  def delete_all_resized_images
    @resized_images&.each(&:close!)
    @resized_images = []
  end
end
