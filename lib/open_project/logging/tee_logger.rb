module OpenProject
  module Logging
    class TeeLogger
      attr_reader :loggers,
                  :stdout,
                  :file

      ##
      # Initialize a stdout/stderr and file logger
      # with the file logger within <rails root>/log/<filename>
      def initialize(log_name, max_level = ::Logger::DEBUG)
        @stdout = ::Logger.new STDOUT
        @file = ::Logger.new Rails.root.join('log', "#{File.basename(log_name, '.log')}.log")

        stdout.level = max_level
        file.level = max_level

        @loggers = [stdout, file]
      end

      %w(log debug info warn error fatal unknown).each do |m|
        define_method(m) do |*args|
          @loggers.map { |t| t.send(m, *args) }
        end
      end
    end
  end
end
