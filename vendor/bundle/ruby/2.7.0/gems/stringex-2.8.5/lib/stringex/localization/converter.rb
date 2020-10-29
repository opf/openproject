# encoding: UTF-8

require 'stringex/localization/conversion_expressions'

module Stringex
  module Localization
    class Converter
      include ConversionExpressions

      attr_reader :ending_whitespace, :options, :starting_whitespace, :string

      def initialize(string, options = {})
        @string = string.dup
        @options = Stringex::Configuration::StringExtensions.default_settings.merge(options)
        string =~ /^(\s+)/
        @starting_whitespace = $1 unless $1 == ''
        string =~ /(\s+)$/
        @ending_whitespace = $1 unless $1 == ''
      end

      def cleanup_accented_html_entities!
        string.gsub! expressions.accented_html_entity, '\1'
      end

      def cleanup_characters!
        string.gsub! expressions.cleanup_characters, ' '
      end

      def cleanup_html_entities!
        string.gsub! expressions.cleanup_html_entities, ''
      end

      def cleanup_smart_punctuation!
        expressions.smart_punctuation.each do |expression, replacement|
          string.gsub! expression, replacement
        end
      end

      def normalize_currency!
        string.gsub!(/(\d+),(\d+)/, '\1\2')
      end

      def smart_strip!
        string.strip!
        @string = "#{starting_whitespace}#{string}#{ending_whitespace}"
      end

      def strip!
        string.strip!
      end

      def strip_html_tags!
        string.gsub! expressions.html_tag, ''
      end

      def translate!(*conversions)
        conversions.each do |conversion|
          send conversion
        end
      end

      protected

      def unreadable_control_characters
        string.gsub! expressions.unreadable_control_characters, ''
      end

      def abbreviations
        string.gsub! expressions.abbreviation do |x|
          x.gsub '.', ''
        end
      end

      def apostrophes
        string.gsub! expressions.apostrophe, '\1\2'
      end

      def characters
        expressions.characters.each do |key, expression|
          next if key == :slash && options[:allow_slash]
          replacement = translate(key)
          replacement = " #{replacement} " unless replacement == '' || key == :dot
          string.gsub! expression, replacement
        end
      end

      def currencies
        if has_currencies?
          [:currencies_complex, :currencies_simple].each do |type|
            expressions.send(type).each do |key, expression|
              string.gsub! expression, " #{translate(key, :currencies)} "
            end
          end
        end
      end

      def ellipses
        string.gsub! expressions.characters[:ellipsis], " #{translate(:ellipsis)} "
      end

      def html_entities
        expressions.html_entities.each do |key, expression|
          string.gsub! expression, translate(key, :html_entities)
        end
        string.squeeze! ' '
      end

      def vulgar_fractions
        expressions.vulgar_fractions.each do |key, expression|
          string.gsub! expression, translate(key, :vulgar_fractions)
        end
      end

      private

      def expressions
        ConversionExpressions
      end

      def has_currencies?
        string =~ CURRENCIES_SUPPORTED
      end

      def translate(key, scope = :characters)
        Localization.translate scope, key
      end
    end
  end
end
