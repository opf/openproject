# frozen_string_literal: true

require 'grape/util/registrable'

module Grape
  module ContentTypes
    extend Util::Registrable

    # Content types are listed in order of preference.
    CONTENT_TYPES = {
      xml: 'application/xml',
      serializable_hash: 'application/json',
      json: 'application/json',
      binary: 'application/octet-stream',
      txt: 'text/plain'
    }.freeze

    class << self
      def content_types_for_settings(settings)
        return if settings.blank?

        settings.each_with_object({}) { |value, result| result.merge!(value) }
      end

      def content_types_for(from_settings)
        if from_settings.present?
          from_settings
        else
          Grape::ContentTypes::CONTENT_TYPES.merge(default_elements)
        end
      end
    end
  end
end
