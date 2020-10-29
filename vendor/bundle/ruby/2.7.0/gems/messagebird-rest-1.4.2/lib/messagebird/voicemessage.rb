require 'messagebird/base'
require 'messagebird/recipient'

module MessageBird
  class VoiceMessage < MessageBird::Base
    attr_accessor :id, :href, :originator, :body, :reference, :language, :voice, :repeat, :ifMachine
    attr_reader :scheduledDatetime, :createdDatetime, :recipients

    def scheduledDatetime=(value)
      @scheduledDatetime = value_to_time(value)
    end

    def createdDatetime=(value)
      @createdDatetime = value_to_time(value)
    end

    def recipients=(json)
      json['items'] = json['items'].map { |r| Recipient.new(r) }
      @recipients = json
    end
  end
end
