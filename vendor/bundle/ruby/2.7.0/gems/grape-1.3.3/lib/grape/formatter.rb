# frozen_string_literal: true

module Grape
  module Formatter
    extend Util::Registrable

    class << self
      def builtin_formatters
        @builtin_formatters ||= {
          json: Grape::Formatter::Json,
          jsonapi: Grape::Formatter::Json,
          serializable_hash: Grape::Formatter::SerializableHash,
          txt: Grape::Formatter::Txt,
          xml: Grape::Formatter::Xml
        }
      end

      def formatters(**options)
        builtin_formatters.merge(default_elements).merge!(options[:formatters] || {})
      end

      def formatter_for(api_format, **options)
        spec = formatters(**options)[api_format]
        case spec
        when nil
          ->(obj, _env) { obj }
        when Symbol
          method(spec)
        else
          spec
        end
      end
    end
  end
end
