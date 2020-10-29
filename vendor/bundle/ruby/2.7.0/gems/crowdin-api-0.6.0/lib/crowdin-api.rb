require 'json'
require 'rest-client'
# require 'byebug'

require "crowdin-api/errors"
require "crowdin-api/methods"
require "crowdin-api/version"


# The Crowdin::API library is used for interactions with a crowdin.com website.
#
# == Example
#
#   require 'crowdin-api'
#   require 'logger'
#
#   crowdin = Crowdin::API.new(:api_key => API_KEY, :project_id => PROJECT_ID)
#   crowdin.log = Logger.new($stderr)
#
module Crowdin
  class API

    class << self
      # Default logger for all Crowdin::API instances
      #
      #   Crowdin::API.log = Logger.new($stderr)
      #
      attr_accessor :log
    end

    # Create a new API object using the given parameters.
    #
    # @param [String] api_key the authentication API key can be found on the project settings page
    # @param [String] project_id the project identifier.
    # @param [String] account_key the account API Key
    # @param [String] base_url the url of the Crowdin API
    #
    def initialize(options = {})
      @api_key     = options.delete(:api_key)
      @project_id  = options.delete(:project_id)
      @account_key = options.delete(:account_key)
      @base_url    = options.delete(:base_url) || 'https://api.crowdin.com'

      @log = nil

      options = {
        :headers                => {},
        :params                 => {},
        :timeout                => nil,
        :key                    => @api_key,
        :'account-key'          => @account_key,
        :json                   => true
      }.merge(options)

      options[:headers] = {
        'Accept'                => 'application/json',
        'User-Agent'            => "crowdin-rb/#{Crowdin::API::VERSION}",
        'X-Ruby-Version'        => RUBY_VERSION,
        'X-Ruby-Platform'       => RUBY_PLATFORM
      }.merge(options[:headers])

      options[:params] = {
        :key                    => @api_key,
        :'account-key'          => @account_key,
        :json                   => true
      }.merge(options[:params])

      RestClient.proxy = ENV['http_proxy'] if ENV['http_proxy']
      @connection = RestClient::Resource.new(@base_url, options)
    end

    def request(params, &block)
      # Returns a query hash with non nil values.
      params[:query].reject! { |_, value| value.nil? } if params[:query]

      case params[:method]
      when :post
        query = @connection.options.merge(params[:query] || {})
        @connection[params[:path]].post(query) { |response, _, _|
          @response = response
        }
      when :get
        query = @connection.options[:params].merge(params[:query] || {})
        @connection[params[:path]].get(:params => query) { |response, _, _|
          @response = response
        }
      end

      log.debug("args: #{@response.request.args}") if log

      if @response.headers[:content_disposition]
        filename = params[:output] || @response.headers[:content_disposition][/attachment; filename="(.+?)"/, 1]
        body = @response.body
        file = open(filename, 'wb')
        file.write(body)
        file.close
        return true
      else
        doc = JSON.load(@response.body)
        log.debug("body: #{doc}") if log

        if doc.kind_of?(Hash) && doc['success'] == false
          code    = doc['error']['code']
          message = doc['error']['message']
          error   = Crowdin::API::Errors::Error.new(code, message)
          raise(error)
        else
          return doc
        end
      end

    end

    # The current logger. If no logger has been set Crowdin::API.log is used.
    #
    def log
      @log || Crowdin::API.log
    end

    # Sets the +logger+ used by this instance of Crowdin::API
    #
    def log= logger
      @log = logger
    end

    private

  end
end
