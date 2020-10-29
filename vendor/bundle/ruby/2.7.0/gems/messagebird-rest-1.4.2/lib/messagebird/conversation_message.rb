require 'messagebird/base'

module MessageBird 
  class ConversationMessage < MessageBird::Base
    attr_accessor :id, :conversationId, :channelId, :direction, :status,
                  :type, :content, :createdDatetime, :updatedDatetime, :fallback

  end
end 
