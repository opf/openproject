require 'delegate'
require 'logger'

module Icalendar

  class Logger < ::SimpleDelegator

    def initialize(sink, level = ::Logger::WARN)
      logger = ::Logger.new(sink)
      logger.level = level
      super logger
    end

  end

end
