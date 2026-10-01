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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "mini_magick"

module Exports::PDF::Common::Attachments
  def resize_image(file_path)
    tmp_file = temp_image_file(File.extname(file_path))

    image = MiniMagick::Image.open(file_path)
    image.resize("x800>")
    image.write(tmp_file)

    tmp_file
  end

  def pdf_embeddable?(content_type)
    %w[image/jpeg image/png image/gif image/webp].include?(content_type)
  end

  def delete_all_resized_images
    @resized_images&.each(&:close!)
    @resized_images = []
  end

  def attachment_image_local_file(attachment)
    attachment.file.local_file
  rescue StandardError => e
    Rails.logger.error "Failed to access attachment #{attachment.id} file: #{e}"
    nil # return nil as if the id was wrong and the attachment obj has not been found
  end

  def attachment_image_filepath(src)
    # images are embedded into markup with the api-path as img.src
    attachment = attachment_by_api_content_src(src)
    return if attachment.nil? || !pdf_embeddable?(attachment.content_type)

    local_file = attachment_image_local_file(attachment)
    return if local_file.nil?

    filename = local_file.path
    filename = convert_gif_to_png(filename) if attachment.content_type == "image/gif"
    filename = convert_webp_to_png(filename) if attachment.content_type == "image/webp"
    filename ? resize_image(filename) : nil
  end

  def temp_image_file(extension)
    tmp_file = Tempfile.new(["temp_image", extension])
    @resized_images ||= []
    @resized_images << tmp_file
    tmp_file.path
  end

  def convert_gif_to_png(filename)
    tmp_file = temp_image_file(".png")

    image = MiniMagick::Image.open(filename)
    image.frames.first.write(tmp_file)
    tmp_file
  end

  def convert_webp_to_png(filename)
    tmp_file = temp_image_file(".png")

    # ImageMagick loads ALL frames of an animated WebP into its pixel cache even
    # when only frame 0 is needed, which can exhaust memory or even cache for large animations.
    # Instead, parse the RIFF/WEBP binary to extract the first ANMF frame as a
    # standalone single-frame WebP, then convert only that.
    source = extract_first_webp_frame(filename) || filename

    image = MiniMagick::Image.open(source)
    image.frames.first.write(tmp_file)
    tmp_file
  end

  # Parses the RIFF/WEBP container and extracts the first animation frame
  # (ANMF chunk) as a standalone single-frame WebP written to a temp file.
  # Returns nil if the file is not an animated WebP.
  #
  # Each ANMF frame in animated WebP is independently encoded (no inter-frame
  # references), so the raw frame chunk is a valid standalone WebP image.
  def extract_first_webp_frame(filename) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    data = File.binread(filename)
    return unless data.bytesize > 12 && data[0, 4] == "RIFF".b && data[8, 4] == "WEBP".b

    webp_type = %W[VP8\x20 VP8L VP8X]
    pos = 12
    while pos + 8 <= data.bytesize
      chunk_id = data[pos, 4]
      chunk_size = data[pos + 4, 4].unpack1("V")
      break if pos + 8 + chunk_size > data.bytesize

      if chunk_id == "ANMF".b && chunk_size > 16
        # ANMF payload: 16 bytes of frame metadata (position, size, duration, flags)
        # followed by the frame image data as a VP8 / VP8L / VP8X chunk.
        # Wrap it in a minimal RIFF/WEBP container to create a single-frame WebP.
        frame_chunk = data[pos + 8 + 16, chunk_size - 16]
        # Reject frames whose payload isn't a recognised WebP bitstream type
        next unless webp_type.map(&:b).include?(frame_chunk[0, 4])

        riff_size = 4 + frame_chunk.bytesize # "WEBP" + frame data
        tmp_frame = temp_image_file(".webp")
        File.binwrite(tmp_frame, "RIFF".b + [riff_size].pack("V") + "WEBP".b + frame_chunk)
        return tmp_frame
      end

      # RIFF chunks are padded to even byte offsets; use & 1 to get the padding.
      pos += 8 + chunk_size + (chunk_size & 1)
    end

    nil
  rescue StandardError => e
    Rails.logger.error "Failed to extract first webp frame: #{e}"
    nil
  end

  def attachment_by_api_content_src(src)
    return if src.empty?

    # we accept absolut linked images
    # (but not hot-linked from elsewhere: https://example.com/another_api/attachments/1/somefile.png)
    #
    # #{api_url_helpers.root_path}api/v3/attachments/:id/content (our default api path)
    # #{api_url_helpers.root_path}attachments/:id/filename.ext (e.g. inserted by drag and drop from the files tab)

    attachment_regex = %r{/attachments/(\d+)/}
    return unless src.start_with?(api_url_helpers.root_path) && src.match?(attachment_regex)

    attachments_id = src.scan(attachment_regex).first.first
    attachment = Attachment.find_by(id: attachments_id.to_i)
    return if attachment.nil?
    return unless attachment.visible?

    attachment
  rescue StandardError
    # if the attachment is not found or the id is invalid, we return nil
    Rails.logger.error "Failed to access attachment #{src}"
    nil
  end
end
