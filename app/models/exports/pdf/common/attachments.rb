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

require "mini_magick"

module Exports::PDF::Common::Attachments
  # Deliberately not MiniMagick::Image#resize: that shells out to `mogrify`, which
  # since ImageMagick 7.1.2-32 writes to a randomized temp name (`<file>-<hex>~`).
  # ImageMagick derives the coder from that name's extension, so the module policy in
  # config/imagemagick/policy.xml denies it.
  # https://github.com/ImageMagick/ImageMagick/issues/8995
  def resize_image(file_path)
    tmp_file = temp_image_file(File.extname(file_path))

    MiniMagick.convert do |convert|
      convert << file_path
      convert.resize("x800>")
      convert << tmp_file
    end

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
    content_type = OpenProject::ContentTypeDetector.detect(filename)
    return unless pdf_embeddable?(content_type)

    filename = convert_gif_to_png(filename) if content_type == "image/gif"
    filename = convert_webp_to_png(filename) if content_type == "image/webp"
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

  WEBP_BITSTREAM_IDS = %W[VP8\x20 VP8L].map(&:b).freeze
  WEBP_CONTAINER_ID = "VP8X".b
  WEBP_ALPHA_ID = "ALPH".b
  WEBP_ANIMATION_FLAG = 0x02
  WEBP_ALPHA_FLAG = 0x10
  WEBP_FRAME_HEADER_SIZE = 16

  def convert_webp_to_png(filename)
    source = webp_single_frame_source(filename)
    return if source.nil?

    tmp_file = temp_image_file(".png")
    image = MiniMagick::Image.open(source)
    image.frames.first.write(tmp_file)
    tmp_file
  end

  # ImageMagick loads ALL frames of an animated WebP into its pixel cache even when
  # only frame 0 is needed, which can exhaust memory or even cache for large
  # animations, so an animation must never reach MiniMagick. Returns the file itself
  # when it carries no animation, a temp file holding only frame 0 when it does, and
  # nil when an animation's frame 0 cannot be read - the caller then drops the image.
  def webp_single_frame_source(filename)
    animated, frame = scan_webp_animation(File.binread(filename))
    return filename unless animated

    unless readable_webp_frame?(frame)
      Rails.logger.error "Skipping animated WebP: frame 0 is not a readable image chunk"
      return
    end

    write_single_frame_webp(frame)
  rescue StandardError => e
    Rails.logger.error "Failed to extract first webp frame: #{e}"
    nil
  end

  # Reports whether the container declares an animation, together with the payload of
  # its first ANMF chunk - nil when there is none to read.
  def scan_webp_animation(data)
    animated = false

    each_webp_chunk(data) do |chunk_id, payload|
      return [true, payload] if chunk_id == "ANMF".b

      animated ||= chunk_id == WEBP_CONTAINER_ID && payload.getbyte(0)&.anybits?(WEBP_ANIMATION_FLAG)
    end

    [animated, nil]
  end

  # A frame opens either with its bitstream or, when it carries transparency, with an
  # ALPH subchunk holding the alpha plane for the bitstream that follows.
  def readable_webp_frame?(frame)
    return false if frame.nil? || frame.bytesize <= WEBP_FRAME_HEADER_SIZE

    image = frame[WEBP_FRAME_HEADER_SIZE..]
    return true if WEBP_BITSTREAM_IDS.include?(image[0, 4])
    return false unless image[0, 4] == WEBP_ALPHA_ID && image.bytesize >= 8

    alpha_size = image[4, 4].unpack1("V")
    WEBP_BITSTREAM_IDS.include?(image[8 + alpha_size + (alpha_size & 1), 4])
  end

  def each_webp_chunk(data)
    return unless webp_container?(data)

    size = data.bytesize
    pos = 12
    while pos + 8 <= size
      chunk_size = data[pos + 4, 4].unpack1("V")
      yield data[pos, 4], data[pos + 8, chunk_size]
      # A chunk running past the container ends the walk, but it is still handed over
      # above so that a truncated animation is recognized as one rather than passed on.
      break if pos + 8 + chunk_size > size

      # RIFF chunks are padded to even byte offsets; use & 1 to get the padding.
      pos += 8 + chunk_size + (chunk_size & 1)
    end
  end

  def webp_container?(data)
    data.bytesize > 12 && data[0, 4] == "RIFF".b && data[8, 4] == "WEBP".b
  end

  # Each ANMF frame in animated WebP is independently encoded (no inter-frame
  # references), so the raw frame chunk is a valid standalone WebP image once
  # wrapped in a minimal RIFF/WEBP container.
  def write_single_frame_webp(frame)
    image = frame[WEBP_FRAME_HEADER_SIZE..]
    body = "WEBP".b + webp_extended_header(frame) + image
    tmp_frame = temp_image_file(".webp")
    File.binwrite(tmp_frame, "RIFF".b + [body.bytesize].pack("V") + body)
    tmp_frame
  end

  # An ALPH subchunk is only legal in the extended format, so such a frame needs a
  # VP8X header to stand alone. The ANMF frame header stores its width and height in
  # the same minus-one 24-bit encoding and order as the VP8X canvas, so they copy over.
  def webp_extended_header(frame)
    return "".b unless frame[WEBP_FRAME_HEADER_SIZE, 4] == WEBP_ALPHA_ID

    payload = [WEBP_ALPHA_FLAG].pack("C") + ("\0".b * 3) + frame[6, 6]
    WEBP_CONTAINER_ID + [payload.bytesize].pack("V") + payload
  end

  def attachment_by_api_content_src(src)
    return if src.empty?

    # we accept absolute linked images
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
    return unless upload_completed?(attachment)

    attachment
  rescue StandardError
    # if the attachment is not found or the id is invalid, we return nil
    Rails.logger.error "Failed to access attachment #{src}"
    nil
  end

  def upload_completed?(attachment)
    attachment.status_scanned? || (attachment.status_uploaded? && !attachment.pending_virus_scan?)
  end
end
