# frozen_string_literal: true

module Aws
  # An auto-refreshing credential provider that works by assuming a
  # role via {Aws::SSO::Client#get_role_credentials} using a cached access
  # token.  This class does NOT implement the SSO login token flow - tokens
  # must generated and refreshed separately by running `aws login` with the
  # correct profile.
  #
  # For more background on AWS SSO see the official
  # [what is SSO](https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html]
  # page.
  #
  # ## Refreshing Credentials from SSO
  #
  # The `SSOCredentials` will auto-refresh the AWS credentials from SSO. In
  # addition to AWS credentials expiring after a given amount of time, the
  # access token generated and cached from `aws login` will also expire.
  # Once this token expires, it will not be usable to refresh AWS credentials,
  # and another token will be needed. The SDK does not manage refreshing of
  # the token value, but this can be done by running `aws login` with the
  # correct profile.
  class SSOCredentials

    include CredentialProvider
    include RefreshingCredentials

    SSO_REQUIRED_OPTS = [:sso_account_id, :sso_region, :sso_role_name, :sso_start_url].freeze

    SSO_LOGIN_GUIDANCE = 'The SSO session associated with this profile has '\
    'expired or is otherwise invalid. To refresh this SSO session run '\
    'aws sso login with the corresponding profile.'.freeze

    # @option options [required, String] :sso_account_id The AWS account ID
    #   that temporary AWS credentials will be resolved for
    #
    # @option options [required, String] :sso_region The AWS region where the
    #   SSO directory for the given sso_start_url is hosted.
    #
    # @option options [required, String] :sso_role_name The corresponding
    #   IAM role in the AWS account that temporary AWS credentials
    #   will be resolved for.
    #
    # @option options [required, String] :sso_start_url The start URL is
    #   provided by the SSO service via the console and is the URL used to
    #   login to the SSO directory. This is also sometimes referred to as
    #   the "User Portal URL"

    # @option options [SSO::Client] :client Optional `SSO::Client`.  If not
    #   provided, a client will be constructed.
    def initialize(options = {})

      missing_keys = SSO_REQUIRED_OPTS.select { |k| options[k].nil? }
      unless missing_keys.empty?
        raise ArgumentError, "Missing required keys: #{missing_keys}"
      end

      @sso_start_url = options.delete(:sso_start_url)
      @sso_region = options.delete(:sso_region)
      @sso_role_name = options.delete(:sso_role_name)
      @sso_account_id = options.delete(:sso_account_id)

      # validate we can read the token file
      read_cached_token

      options[:region] = @sso_region
      options[:credentials] = nil
      @client = options[:client] || SSO::Client.new(options)
      super
    end

    # @return [STS::Client]
    attr_reader :client

    private

    def read_cached_token
      cached_token = Json.load(File.read(sso_cache_file))
      # validation
      unless cached_token['accessToken'] && cached_token['expiresAt']
        raise ArgumentError, 'Missing required field(s)'
      end
      expires_at = DateTime.parse(cached_token['expiresAt'])
      if expires_at < DateTime.now
        raise ArgumentError, 'Cached SSO Token is expired.'
      end
      cached_token
    rescue Aws::Json::ParseError, ArgumentError
      raise Errors::InvalidSSOCredentials, SSO_LOGIN_GUIDANCE
    end

    def refresh
      cached_token = read_cached_token
      c = @client.get_role_credentials(
        account_id: @sso_account_id,
        role_name: @sso_role_name,
        access_token: cached_token['accessToken']
      ).role_credentials

      @credentials = Credentials.new(
        c.access_key_id,
        c.secret_access_key,
        c.session_token
      )
      @expiration = c.expiration
    end

    def sso_cache_file
      start_url_sha1 = OpenSSL::Digest::SHA1.hexdigest(@sso_start_url.encode('utf-8'))
      File.join(Dir.home, '.aws', 'sso', 'cache', "#{start_url_sha1}.json")
    rescue ArgumentError
      # Dir.home raises ArgumentError when ENV['home'] is not set
      raise ArgumentError, "Unable to load sso_cache_file: ENV['HOME'] is not set."
    end
  end
end
