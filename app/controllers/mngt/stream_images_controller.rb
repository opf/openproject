# frozen_string_literal: true

module Mngt
  class StreamImagesController < ApplicationController
    before_action :require_login
    no_authorization_required! :create

    def create
      uploaded = params[:image]
      return render json: { error: "No file" }, status: :bad_request if uploaded.blank?

      processed_io, content_type, filename = compress_image(uploaded)

      chat_image = Mngt::ChatImage.new(author: current_user)
      chat_image.file.attach(io: processed_io, filename:, content_type:)

      if chat_image.save
        render json: { url: rails_blob_path(chat_image.file), id: chat_image.id }
      else
        render json: { errors: chat_image.errors.full_messages }, status: :unprocessable_entity
      end
    ensure
      # Only close/unlink if we created a new tempfile (not the original uploaded tempfile)
      if defined?(processed_io) && processed_io && processed_io != uploaded&.tempfile
        processed_io.close
        processed_io.unlink
      end
    end

    private

    def compress_image(uploaded)
      base_name = File.basename(uploaded.original_filename.to_s, ".*")

      # GIF: preserve as-is — animated GIFs would break on format conversion
      if uploaded.content_type == "image/gif"
        return [uploaded.tempfile, "image/gif", "#{base_name}.gif"]
      end

      processed = ImageProcessing::MiniMagick
        .source(uploaded.tempfile)
        .resize_to_limit(1920, 1920)
        .saver(quality: 80)
        .convert("jpg")
        .call

      [processed, "image/jpeg", "#{base_name}.jpg"]
    end
  end
end
