# frozen_string_literal: true

module Grape
  module DSL
    module Logger
      include Grape::DSL::Settings

      attr_writer :logger

      # Set or retrive the configured logger. If none was configured, this
      # method will create a new one, logging to stdout.
      # @param logger [Object] the new logger to use
      def logger(logger = nil)
        if logger
          global_setting(:logger, logger)
        else
          global_setting(:logger) || global_setting(:logger, ::Logger.new($stdout))
        end
      end
    end
  end
end
