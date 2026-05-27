# frozen_string_literal: true

module Mngt
  class ChatImage < ApplicationRecord
    ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
    MAX_FILE_SIZE = 10.megabytes

    self.table_name = "mngt_chat_images"

    belongs_to :author, class_name: "User"
    has_one_attached :file

    validate :file_must_be_attached
    validate :file_content_type_must_be_allowed, if: -> { file.attached? }
    validate :file_size_must_be_within_limit,    if: -> { file.attached? }

    private

    def file_must_be_attached
      errors.add(:file, :blank) unless file.attached?
    end

    def file_content_type_must_be_allowed
      unless ALLOWED_CONTENT_TYPES.include?(file.blob.content_type)
        errors.add(:file, :invalid, message: "tipo não permitido: #{file.blob.content_type}")
      end
    end

    def file_size_must_be_within_limit
      if file.blob.byte_size > MAX_FILE_SIZE
        errors.add(:file, :file_too_large, message: "excede 10 MB")
      end
    end
  end
end
