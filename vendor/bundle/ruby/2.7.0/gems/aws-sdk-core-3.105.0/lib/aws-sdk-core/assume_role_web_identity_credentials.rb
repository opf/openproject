# frozen_string_literal: true

require 'set'
require 'securerandom'
require 'base64'

module Aws

  # An auto-refreshing credential provider that works by assuming
  # a role via {Aws::STS::Client#assume_role_with_web_identity}.
  #
  #     role_credentials = Aws::AssumeRoleWebIdentityCredentials.new(
  #       client: Aws::STS::Client.new(...),
  #       role_arn: "linked::account::arn",
  #       web_identity_token_file: "/path/to/token/file",
  #       role_session_name: "session-name"
  #       ...
  #     )
  #     For full list of parameters accepted
  #     @see Aws::STS::Client#assume_role_with_web_identity 
  #
  #
  # If you omit `:client` option, a new {STS::Client} object will be
  # constructed.
  class AssumeRoleWebIdentityCredentials

    include CredentialProvider
    include RefreshingCredentials

    # @param [Hash] options
    # @option options [required, String] :role_arn the IAM role
    #   to be assumed
    #
    # @option options [required, String] :web_identity_token_file
    #   absolute path to the file on disk containing OIDC token
    #
    # @option options [String] :role_session_name the IAM session
    #   name used to distinguish session, when not provided, base64
    #   encoded UUID is generated as the session name
    #
    # @option options [STS::Client] :client
    def initialize(options = {})
      client_opts = {}
      @assume_role_web_identity_params = {}
      @token_file = options.delete(:web_identity_token_file)
      options.each_pair do |key, value|
        if self.class.assume_role_web_identity_options.include?(key)
          @assume_role_web_identity_params[key] = value
        else
          client_opts[key] = value
        end
      end

      unless @assume_role_web_identity_params[:role_session_name]
        # not provided, generate encoded UUID as session name
        @assume_role_web_identity_params[:role_session_name] = _session_name
      end
      @client = client_opts[:client] || STS::Client.new(client_opts.merge(credentials: false))
      super
    end

    # @return [STS::Client]
    attr_reader :client

    private

    def refresh
      # read from token file everytime it refreshes
      @assume_role_web_identity_params[:web_identity_token] = _token_from_file(@token_file)

      c = @client.assume_role_with_web_identity(
        @assume_role_web_identity_params).credentials
      @credentials = Credentials.new(
        c.access_key_id,
        c.secret_access_key,
        c.session_token
      )
      @expiration = c.expiration
    end

    def _token_from_file(path)
      unless path && File.exist?(path)
        raise Aws::Errors::MissingWebIdentityTokenFile.new
      end
      File.read(path)
    end

    def _session_name
      Base64.strict_encode64(SecureRandom.uuid)
    end

    class << self

      # @api private
      def assume_role_web_identity_options
        @arwio ||= begin
          input = STS::Client.api.operation(:assume_role_with_web_identity).input
          Set.new(input.shape.member_names)
        end
      end

    end
  end
end
