require 'messagebird/base'
require 'messagebird/contact'
require 'messagebird/conversation_channel'

module MessageBird 
  class Conversation < MessageBird::Base
    attr_accessor :id, :status, :lastUsedChannelId, :contactId
    attr_reader :contact, :channels, :messages, :createdDatetime,
                :updatedDatetime, :lastReceivedDatetime

    CONVERSATION_STATUS_ACTIVE = 'active'
    CONVERSATION_STATUS_ARCHIVED = 'archived'
    WEBHOOK_EVENT_CONVERSATION_CREATED = 'conversation.created'
    WEBHOOK_EVENT_CONVERSATION_UPDATED = 'conversation.updated'
    WEBHOOK_EVENT_MESSAGE_CREATED = 'message.created'
    WEBHOOK_EVENT_MESSAGE_UPDATED = 'message.updated'

    def contact=(value)
      @contact = Contact.new(value)
    end

    def channels=(json)
      @channels = json.map { |c| MessageBird::ConversationChannel.new(c) }
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

    def lastReceivedDatetime=(value)
      @lastReceivedDatetime = value_to_time(value)
    end
  end 
end 
