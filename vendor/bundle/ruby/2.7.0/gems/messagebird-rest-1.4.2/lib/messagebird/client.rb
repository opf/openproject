require 'json'
require 'net/https'
require 'uri'

require 'messagebird/balance'
require 'messagebird/contact'
require 'messagebird/conversation'
require 'messagebird/conversation_client'
require 'messagebird/conversation_message'
require 'messagebird/conversation_webhook'
require 'messagebird/error'
require 'messagebird/group'
require 'messagebird/hlr'
require 'messagebird/http_client'
require 'messagebird/list'
require 'messagebird/lookup'
require 'messagebird/message'
require 'messagebird/verify'
require 'messagebird/voicemessage'

module MessageBird
  class ErrorException < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end
  end

  class Client
    attr_reader :access_key, :http_client, :conversation_client

    def initialize(access_key = nil, http_client = nil)
      @access_key = access_key || ENV['MESSAGEBIRD_ACCESS_KEY']
      @http_client = http_client || HttpClient.new(@access_key)
      @conversation_client = http_client || ConversationClient.new(@access_key)
    end

    def conversation_request(method, path, params={})
      response_body = @conversation_client.request(method, path, params)
      return if response_body.nil? || response_body.empty?
      parse_body(response_body)
    end

    def request(method, path, params={})
      response_body = @http_client.request(method, path, params)
      return if response_body.empty?
      parse_body(response_body)
    end

    def parse_body(body)
      json = JSON.parse(body)

      # If the request returned errors, create Error objects and raise.
      if json.has_key?('errors')
        raise ErrorException, json['errors'].map { |e| Error.new(e) }
      end

      json
    end

    ## Conversations
    # Send a conversation message
    def send_conversation_message(from, to, params={})
      ConversationMessage.new(conversation_request(
        :post,
        'send', 
        params.merge({
          :from => from,
          :to => to,
        })))
    end

    # Start a conversation
    def start_conversation(to, channelId, params={})
      Conversation.new(conversation_request(
        :post,
        'conversations/start',
        params.merge({
          :to => to,
          :channelId => channelId,
        })))
    end

    def conversation_list(limit = 0, offset = 0)
      List.new(Conversation, conversation_request(:get, "conversations?limit=#{limit}&offset=#{offset}"))
    end

    def conversation(id)
      Conversation.new(conversation_request(:get, "conversations/#{id}"))
    end

    def conversation_update(id, status)
      Conversation.new(conversation_request(:patch, "conversations/#{id}", :status => status))
    end
    
    def conversation_reply(id, params={})
      ConversationMessage.new(conversation_request(:post, "conversations/#{id}/messages", params))
    end
    
    def conversation_messages_list(id, limit=0, offset=0)
      List.new(ConversationMessage, conversation_request(:get, "conversations/#{id}/messages?limit=#{limit}&offset=#{offset}"))
    end
    
    def conversation_message(id)
      ConversationMessage.new(conversation_request(:get, "messages/#{id}"))
    end
    
    def conversation_webhook_create(channelId, url, events=[])
      ConversationWebhook.new(conversation_request(
        :post,
        "webhooks",
        :channelId => channelId,
        :url => url,
        :events => events
      ))
    end

    def conversation_webhooks_list(limit=0, offset=0)
      List.new(ConversationWebhook, conversation_request(:get,"webhooks?limit=#{limit}&offset=#{offset}"))
    end

    def conversation_webhook_update(id, params={})
      ConversationWebhook.new(conversation_request(:patch,"webhooks/#{id}",params))
    end

    def conversation_webhook(id)
      ConversationWebhook.new(conversation_request(:get,"webhooks/#{id}"))
    end

    def conversation_webhook_delete(id)
      conversation_request(:delete,"webhooks/#{id}")
    end

    # Retrieve your balance.
    def balance
      Balance.new(request(:get, 'balance'))
    end

    # Retrieve the information of specific HLR.
    def hlr(id)
      HLR.new(request(:get, "hlr/#{id.to_s}"))
    end

    # Create a new HLR.
    def hlr_create(msisdn, reference)
      HLR.new(request(
        :post,
        'hlr',
        :msisdn    => msisdn,
        :reference => reference))
    end

    # Retrieve the information of specific Verify.
    def verify(id)
      Verify.new(request(:get, "verify/#{id.to_s}"))
    end

    # Generate a new One-Time-Password message.
    def verify_create(recipient, params={})
      Verify.new(request(
          :post,
          'verify',
          params.merge({
              :recipient => recipient
          })
      ))
    end

    # Verify the One-Time-Password.
    def verify_token(id, token)
      Verify.new(request(:get, "verify/#{id.to_s}?token=#{token}"))
    end

    # Delete a Verify
    def verify_delete(id)
      Verify.new(request(:delete, "verify/#{id.to_s}"))
    end

    # Retrieve the information of specific message.
    def message(id)
      Message.new(request(:get, "messages/#{id.to_s}"))
    end

    # Create a new message.
    def message_create(originator, recipients, body, params={})
      # Convert an array of recipients to a comma-separated string.
      recipients = recipients.join(',') if recipients.kind_of?(Array)

      Message.new(request(
        :post,
        'messages',
        params.merge({
          :originator => originator.to_s,
          :body       => body.to_s,
          :recipients => recipients })))
    end

    # Retrieve the information of a specific voice message.
    def voice_message(id)
      VoiceMessage.new(request(:get, "voicemessages/#{id.to_s}"))
    end

    # Create a new voice message.
    def voice_message_create(recipients, body, params={})
      # Convert an array of recipients to a comma-separated string.
      recipients = recipients.join(',') if recipients.kind_of?(Array)

      VoiceMessage.new(request(
        :post,
        'voicemessages',
        params.merge({ :recipients => recipients, :body => body.to_s })))
    end

    def lookup(phoneNumber, params={})
      Lookup.new(request(:get, "lookup/#{phoneNumber}", params))
    end

    def lookup_hlr_create(phoneNumber, params={})
      HLR.new(request(:post, "lookup/#{phoneNumber}/hlr", params))
    end

    def lookup_hlr(phoneNumber, params={})
      HLR.new(request(:get, "lookup/#{phoneNumber}/hlr", params))
    end

    def contact_create(phoneNumber, params={})
      Contact.new(request(
                      :post,
                      'contacts',
                      params.merge({ :msisdn => phoneNumber.to_s })))
    end

    def contact(id)
      Contact.new(request(:get, "contacts/#{id}"))
    end

    def contact_delete(id)
      request(:delete, "contacts/#{id}")
    end

    def contact_update(id, params={})
      request(:patch, "contacts/#{id}", params)
    end

    def contact_list(limit = 0, offset = 0)
      List.new(Contact, request(:get, "contacts?limit=#{limit}&offset=#{offset}"))
    end

    def group(id)
      Group.new(request(:get, "groups/#{id}"))
    end

    def group_create(name)
      Group.new(request(:post, 'groups', { :name => name }))
    end

    def group_delete(id)
      request(:delete, "groups/#{id}")
    end

    def group_list(limit = 0, offset = 0)
      List.new(Group, request(:get, "groups?limit=#{limit}&offset=#{offset}"))
    end

    def group_update(id, name)
      request(:patch, "groups/#{id}", { :name => name })
    end

    def group_add_contacts(group_id, contact_ids)
      # We expect an array, but we can handle a string ID as well...
      contact_ids = [contact_ids] if contact_ids.is_a? String

      query = add_contacts_query(contact_ids)

      request(:get, "groups/#{group_id}?#{query}")
    end

    def group_delete_contact(group_id, contact_id)
      request(:delete, "groups/#{group_id}/contacts/#{contact_id}")
    end

    private # Applies to every method below this line

    def add_contacts_query(contact_ids)
      # add_contacts_query gets a query string to add contacts to a group.
      # We're using the alternative "/foo?_method=PUT&key=value" format to send
      # the contact IDs as GET params. Sending these in the request body would
      # require a painful workaround, as the client sends request bodies as
      # JSON by default. See also:
      # https://developers.messagebird.com/docs/alternatives.

      '_method=PUT&' + contact_ids.map { |id| "ids[]=#{id}" }.join('&')
    end

  end
end
