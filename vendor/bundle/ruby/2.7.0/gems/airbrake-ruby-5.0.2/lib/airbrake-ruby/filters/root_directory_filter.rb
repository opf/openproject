module Airbrake
  module Filters
    # Replaces root directory with a label.
    # @api private
    class RootDirectoryFilter
      # @return [String]
      PROJECT_ROOT_LABEL = '/PROJECT_ROOT'.freeze

      # @return [Integer]
      attr_reader :weight

      def initialize(root_directory)
        @root_directory = root_directory
        @weight = 100
      end

      # @macro call_filter
      def call(notice)
        notice[:errors].each do |error|
          error[:backtrace].each do |frame|
            next unless (file = frame[:file])

            file.sub!(/\A#{@root_directory}/, PROJECT_ROOT_LABEL)
          end
        end
      end
    end
  end
end
