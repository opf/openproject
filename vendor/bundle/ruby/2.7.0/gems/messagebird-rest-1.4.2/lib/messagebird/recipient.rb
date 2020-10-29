require 'messagebird/base'

module MessageBird
  class Recipient < MessageBird::Base
    attr_accessor :recipient, :status
    attr_reader :statusDatetime

    def statusDatetime=(value)
      @statusDatetime = value_to_time(value)
    end
  end
end
