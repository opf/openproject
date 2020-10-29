# frozen_string_literal: true

module Doorkeeper
  class Server
    attr_reader :context

    def initialize(context)
      @context = context
    end

    def authorization_request(strategy)
      klass = Request.authorization_strategy(strategy)
      klass.new(self)
    end

    def token_request(strategy)
      klass = Request.token_strategy(strategy)
      klass.new(self)
    end

    # TODO: context should be the request
    def parameters
      context.request.parameters
    end

    def client
      @client ||= OAuth::Client.authenticate(credentials)
    end

    def current_resource_owner
      context.send :current_resource_owner
    end

    # TODO: Use configuration and evaluate proper context on block
    def resource_owner
      context.send :resource_owner_from_credentials
    end

    def credentials
      methods = Doorkeeper.config.client_credentials_methods
      @credentials ||= OAuth::Client::Credentials.from_request(context.request, *methods)
    end
  end
end
