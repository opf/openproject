# frozen_string_literal: true

require 'forwardable'
require 'mustermann/grape'
require 'grape/util/cache'

module Grape
  class Router
    class Pattern
      DEFAULT_PATTERN_OPTIONS   = { uri_decode: true }.freeze
      DEFAULT_SUPPORTED_CAPTURE = %i[format version].freeze

      attr_reader :origin, :path, :pattern, :to_regexp

      extend Forwardable
      def_delegators :pattern, :named_captures, :params
      def_delegators :to_regexp, :===
      alias match? ===

      def initialize(pattern, **options)
        @origin  = pattern
        @path    = build_path(pattern, **options)
        @pattern = Mustermann::Grape.new(@path, **pattern_options(options))
        @to_regexp = @pattern.to_regexp
      end

      private

      def pattern_options(options)
        capture = extract_capture(**options)
        options = DEFAULT_PATTERN_OPTIONS.dup
        options[:capture] = capture if capture.present?
        options
      end

      def build_path(pattern, anchor: false, suffix: nil, **_options)
        unless anchor || pattern.end_with?('*path')
          pattern = +pattern
          pattern << '/' unless pattern.end_with?('/')
          pattern << '*path'
        end

        pattern = -pattern.split('/').tap do |parts|
          parts[parts.length - 1] = '?' + parts.last
        end.join('/') if pattern.end_with?('*path')

        PatternCache[[pattern, suffix]]
      end

      def extract_capture(requirements: {}, **options)
        requirements = {}.merge(requirements)
        DEFAULT_SUPPORTED_CAPTURE.each_with_object(requirements) do |field, capture|
          option = Array(options[field])
          capture[field] = option.map(&:to_s) if option.present?
        end
      end

      class PatternCache < Grape::Util::Cache
        def initialize
          @cache = Hash.new do |h, (pattern, suffix)|
            h[[pattern, suffix]] = -"#{pattern}#{suffix}"
          end
        end
      end
    end
  end
end
