require 'time'

require 'messagebird/base'

module MessageBird
  class Verify < MessageBird::Base
    attr_accessor :id, :recipient, :reference, :status, :href
    attr_reader :createdDatetime, :validUntilDatetime

    def createdDatetime=(value)
      @createdDatetime = value_to_time(value)
    end

    def validUntilDatetime=(value)
      @validUntilDatetime = value_to_time(value)
    end
  end
end
