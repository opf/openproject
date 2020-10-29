# frozen_string_literal: true

module Grape
  module ErrorFormatter
    extend Util::Registrable

    class << self
      def builtin_formatters
        @builtin_formatters ||= {
          serializable_hash: Grape::ErrorFormatter::Json,
          json: Grape::ErrorFormatter::Json,
          jsonapi: Grape::ErrorFormatter::Json,
          txt: Grape::ErrorFormatter::Txt,
          xml: Grape::ErrorFormatter::Xml
        }
      end

      def formatters(**options)
        builtin_formatters.merge(default_elements).merge!(options[:error_formatters] || {})
      end

      def formatter_for(api_format, **options)
        spec = formatters(**options)[api_format]
        case spec
        when nil
          options[:default_error_formatter] || Grape::ErrorFormatter::Txt
        when Symbol
          method(spec)
        else
          spec
        end
      end
    end
  end
end
