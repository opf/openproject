module Airbrake
  module Filters
    # Replaces paths to gems with a placeholder.
    # @api private
    class GemRootFilter
      # @return [String]
      GEM_ROOT_LABEL = '/GEM_ROOT'.freeze

      # @return [Integer]
      attr_reader :weight

      def initialize
        @weight = 120
      end

      # @macro call_filter
      def call(notice)
        return unless defined?(Gem)

        notice[:errors].each do |error|
          Gem.path.each do |gem_path|
            error[:backtrace].each do |frame|
              # If the frame is unparseable, then 'file' is nil, thus nothing to
              # filter (all frame's data is in 'function' instead).
              next unless (file = frame[:file])

              frame[:file] = file.sub(/\A#{gem_path}/, GEM_ROOT_LABEL)
            end
          end
        end
      end
    end
  end
end
