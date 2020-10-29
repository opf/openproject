require 'messagebird/base'

module MessageBird 
  class ConversationWebhook < MessageBird::Base
    attr_accessor :id, :events, :channelId, :url, :status, :createdDatetime, :updatedDatetime
  end
end
