require 'time'

require 'messagebird/base'

module MessageBird
  class HLR < MessageBird::Base
    attr_accessor :id, :href, :msisdn, :network, :reference, :status, :details
    attr_reader :createdDatetime, :statusDatetime

    def createdDatetime=(value)
      @createdDatetime = value_to_time(value)
    end

    def statusDatetime=(value)
      @statusDatetime = value_to_time(value)
    end
  end
end
