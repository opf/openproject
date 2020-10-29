require 'messagebird/base'
require 'messagebird/recipient'

module MessageBird
  class Message < MessageBird::Base
    attr_accessor :id, :href, :direction, :type, :originator, :body, :reference,
                  :validity, :gateway, :typeDetails, :datacoding, :mclass
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
