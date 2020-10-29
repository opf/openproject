# frozen_string_literal: true

module Prawn
  module Markup
    # Normalizes HTML markup:
    #  * assert that self-closing tags are always closed
    #  * replace html entities with their UTF-8 correspondent string
    #  * normalize white space
    #  * wrap entire content into <root> tag
    class Normalizer
      SELF_CLOSING_ELEMENTS = %w[br img hr].freeze

      REPLACE_ENTITIES = {
        nbsp: ' '
      }.freeze

      attr_reader :html

      def initialize(html)
        @html = html.dup
      end

      def normalize
        close_self_closing_elements
        normalize_spaces
        replace_html_entities
        "<body>#{html}</body>"
      end

      private

      def close_self_closing_elements
        html.gsub!(/<(#{SELF_CLOSING_ELEMENTS.join('|')})[^>]*>/i) do |tag|
          tag[-1] = '/>' unless tag.end_with?('/>')
          tag
        end
      end

      def normalize_spaces
        html.gsub!(/\s+/, ' ')
      end

      def replace_html_entities
        REPLACE_ENTITIES.each do |entity, string|
          html.gsub!(/&#{entity};/, string)
        end
      end

    end
  end
end
