require 'messagebird/base'

module MessageBird
  class ConversationChannel < MessageBird::Base
    attr_accessor :id, :name, :platformId, :status
    attr_reader :createdDatetime, :updatedDatetime

    def createdDatetime=(value)
      @createdDatetime = value_to_time(value)
    end

    def updatedDatetime=(value)
      @updatedDatetime = value_to_time(value)
    end

  end
end
