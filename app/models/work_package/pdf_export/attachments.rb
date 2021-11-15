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

module WorkPackage::PDFExport::Attachments
  ##
  # Creates cells for each attachment of the work package
  #
  def make_attachments_cells(attachments)
    # Distribute all attachments on one line, this will work well with up to ~5 attachments.
    # more than that will be resized further
    available_width = (pdf.bounds.width / attachments.length) * 0.98

    attachments
      .map { |attachment| make_attachment_cell attachment, available_width }
      .compact
  end

  private

  def make_attachment_cell(attachment, available_width)
    # We can only include JPG and PNGs, maybe we want to add a text box for other attachments here
    return nil unless pdf_embeddable?(attachment)

    # Access the local file. For Carrierwave attachments, this will be blocking.
    file_path = attachment.file.local_file.path

    # Let's not include the raw images as the sum of all images can hit the memory limit of the worker process.
    # As we do not need the full image size when printing small images into the PDF let's reduce it on the fly.
    # It uses CPU and time. However, we don't expect that feature to get used often.
    resized_file_path = resize_image(file_path)

    # Fit the image roughly in the center of each cell
    pdf.make_cell(image: resized_file_path, fit: [available_width, 125], position: :center)
  rescue StandardError => e
    Rails.logger.error { "Failed to attach work package image to PDF: #{e} #{e.message}" }
    nil
  end

  def resize_image(file_path)
    resized_file_path = extend_file_name_in_path(file_path, '__x325')
    image = MiniMagick::Image.open(file_path)
    image.resize("x325")
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

  def pdf_embeddable?(attachment)
    %w[image/jpeg image/png].include?(attachment.content_type)
  end

  def delete_all_resized_images
    @resized_image_paths.each do |file_path|
      File.delete(file_path)
    end
  end
end
