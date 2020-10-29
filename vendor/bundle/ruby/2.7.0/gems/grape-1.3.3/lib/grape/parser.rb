# frozen_string_literal: true

module Grape
  module Parser
    extend Util::Registrable

    class << self
      def builtin_parsers
        @builtin_parsers ||= {
          json: Grape::Parser::Json,
          jsonapi: Grape::Parser::Json,
          xml: Grape::Parser::Xml
        }
      end

      def parsers(**options)
        builtin_parsers.merge(default_elements).merge!(options[:parsers] || {})
      end

      def parser_for(api_format, **options)
        spec = parsers(**options)[api_format]
        case spec
        when nil
          nil
        when Symbol
          method(spec)
        else
          spec
        end
      end
    end
  end
end
