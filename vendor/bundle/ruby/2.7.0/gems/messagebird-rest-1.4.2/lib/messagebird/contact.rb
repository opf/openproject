require 'messagebird/base'
require 'messagebird/custom_details'
require 'messagebird/group_reference'
require 'messagebird/message_reference'

module MessageBird
  class Contact < MessageBird::Base
    attr_accessor :id, :href, :msisdn, :firstName, :lastName
    attr_reader :customDetails, :groups, :messages, :createdDatetime, :updatedDatetime

    def customDetails=(value)
      @customDetails = MessageBird::CustomDetails.new(value)
    end

    def groups=(value)
      @groups = MessageBird::GroupReference.new(value)
    end

    def messages=(value)
      @messages = MessageBird::MessageReference.new(value)
    end

    def createdDatetime=(value)
      @createdDatetime = value_to_time(value)
    end

    def updatedDatetime=(value)
      @updatedDatetime = value_to_time(value)
    end
  end
end
