# frozen_string_literal: true

module Bootsnap
  module LoadPathCache
    class RealpathCache
      def initialize
        @cache = Hash.new { |h, k| h[k] = realpath(*k) }
      end

      def call(*key)
        @cache[key]
      end

      private

      def realpath(caller_location, path)
        base = File.dirname(caller_location)
        abspath = File.expand_path(path, base).freeze
        find_file(abspath)
      end

      def find_file(name)
        return File.realpath(name).freeze if File.exist?(name)
        CACHED_EXTENSIONS.each do |ext|
          filename = "#{name}#{ext}"
          return File.realpath(filename).freeze if File.exist?(filename)
        end
        name
      end
    end
  end
end
