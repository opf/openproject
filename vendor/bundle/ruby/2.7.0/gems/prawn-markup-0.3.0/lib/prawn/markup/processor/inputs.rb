# frozen_string_literal: true

module Prawn
  module Markup
    module Processor::Inputs

      DEFAULT_CHECKABLE_CHARS = {
        checkbox: {
          checked: '☑',
          unchecked: '☐'
        },
        radio: {
          checked: '◉',
          unchecked: '○'
        }
      }.freeze

      def self.prepended(base)
        base.known_elements.push('input')
      end

      def start_input
        type = current_attrs['type'].to_sym
        if DEFAULT_CHECKABLE_CHARS.keys.include?(type)
          append_checked_symbol(type)
        end
      end

      private

      def append_checked_symbol(type)
        char = checkable_symbol(type)
        append_text(build_font_tag(char))
      end

      def checkable_symbol(type)
        state = current_attrs.key?('checked') ? :checked : :unchecked
        dig_options(:input, type, state) || DEFAULT_CHECKABLE_CHARS[type][state]
      end

      def symbol_font_options
        @symbol_font_options ||= {
          name: dig_options(:input, :symbol_font),
          size: dig_options(:input, :symbol_font_size)
        }.compact
      end

      def build_font_tag(content)
        return content if symbol_font_options.empty?

        out = +'<font'
        symbol_font_options.each do |key, value|
          out << " #{key}=\"#{value}\""
        end
        out << '>'
        out << content
        out << '</font>'
      end
    end
  end
end
