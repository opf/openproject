require 'net/https'
require 'uri'
require 'json'
require 'messagebird/http_client'

module MessageBird
  class ConversationClient < HttpClient
    ENDPOINT  = 'https://conversations.messagebird.com/v1/'

    def endpoint() 
      ENDPOINT
    end

    def prepare_request(request, params={})
      request.body = params.to_json
      request
    end
  end
end
