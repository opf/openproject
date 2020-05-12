Doorkeeper.configure do
  # Change the ORM that doorkeeper will use (needs plugins)
  orm :active_record

  # This block will be called to check whether the resource owner is authenticated or not.
  resource_owner_authenticator do
    logged_user = session[:user_id] && User.active.find_by(id: session[:user_id])
    if logged_user.present?
      logged_user
    else
      redirect_to(signin_path(back_url: request.fullpath))
    end
  end

  # If you are planning to use Doorkeeper in Rails 5 API-only application, then you might
  # want to use API mode that will skip all the views management and change the way how
  # Doorkeeper responds to a requests.
  #
  # api_only

  # Enforce token request content type to application/x-www-form-urlencoded.
  # It is not enabled by default to not break prior versions of the gem.
  #
  enforce_content_type

  # Authorization Code expiration time (default 10 minutes).
  #
  authorization_code_expires_in 10.minutes

  # Access token expiration time (default 2 hours).
  # If you want to disable expiration, set this to nil.
  #
  access_token_expires_in 2.hours

  # Assign custom TTL for access tokens. Will be used instead of access_token_expires_in
  # option if defined. `context` has the following properties available
  #
  # `client` - the OAuth client application (see Doorkeeper::OAuth::Client)
  # `grant_type` - the grant type of the request (see Doorkeeper::OAuth)
  # `scopes` - the requested scopes (see Doorkeeper::OAuth::Scopes)
  #
  # custom_access_token_expires_in do |context|
  #   context.client.application.additional_settings.implicit_oauth_expiration
  # end

  # Use a custom class for generating the access token.
  # See https://github.com/doorkeeper-gem/doorkeeper#custom-access-token-generator
  #
  # access_token_generator '::Doorkeeper::JWT'

  # The controller Doorkeeper::ApplicationController inherits from.
  # Defaults to ActionController::Base.
  # See https://github.com/doorkeeper-gem/doorkeeper#custom-base-controller
  #
  base_controller '::OAuth::AuthBaseController'

  # Enable hashing and bcrypt-hashing of token secrets
  # and application secrets, respectively.
  hash_token_secrets
  hash_application_secrets

  # Reuse access token for the same resource owner within an application (disabled by default).
  #
  # This option protects your application from creating new tokens before old valid one becomes
  # expired so your database doesn't bloat. Keep in mind that when this option is `on` Doorkeeper
  # doesn't updates existing token expiration time, it will create a new token instead.
  # Rationale: https://github.com/doorkeeper-gem/doorkeeper/issues/383
  #
  # reuse_access_token

  # Issue access tokens with refresh token (disabled by default), you may also
  # pass a block which accepts `context` to customize when to give a refresh
  # token or not. Similar to `custom_access_token_expires_in`, `context` has
  # the properties:
  #
  # `client` - the OAuth client application (see Doorkeeper::OAuth::Client)
  # `grant_type` - the grant type of the request (see Doorkeeper::OAuth)
  # `scopes` - the requested scopes (see Doorkeeper::OAuth::Scopes)
  #
  use_refresh_token

  # Forbids creating/updating applications with arbitrary scopes that are
  # not in configuration, i.e. `default_scopes` or `optional_scopes`.
  # (disabled by default)
  #
  enforce_configured_scopes

  # Provide support for an owner to be assigned to each registered application (disabled by default)
  # Optional parameter confirmation: true (default false) if you want to enforce ownership of
  # a registered application
  # Note: you must also run the rails g doorkeeper:application_owner generator to provide the necessary support
  #
  enable_application_owner confirmation: false

  # Define access token scopes for your provider
  # For more information go to
  # https://github.com/doorkeeper-gem/doorkeeper/wiki/Using-Scopes
  #
  default_scopes :api_v3

  # Change the way client credentials are retrieved from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:client_id` and `:client_secret` params from the `params` object.
  # Check out https://github.com/doorkeeper-gem/doorkeeper/wiki/Changing-how-clients-are-authenticated
  # for more information on customization
  #
  # client_credentials :from_basic, :from_params

  # Change the way access token is authenticated from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:access_token` or `:bearer_token` params from the `params` object.
  # Check out https://github.com/doorkeeper-gem/doorkeeper/wiki/Changing-how-clients-are-authenticated
  # for more information on customization
  #
  # access_token_methods :from_bearer_authorization, :from_access_token_param, :from_bearer_param

  # Forces the usage of the HTTPS protocol in non-native redirect uris (enabled
  # by default in non-development environments). OAuth2 delegates security in
  # communication to the HTTPS protocol so it is wise to keep this enabled.
  #
  # Callable objects such as proc, lambda, block or any object that responds to
  # #call can be used in order to allow conditional checks (to allow non-SSL
  # redirects to localhost for example).
  #
  # force_ssl_in_redirect_uri !Rails.env.development?
  #
  # force_ssl_in_redirect_uri { |uri| uri.host != 'localhost' }

  # Specify what redirect URI's you want to block during Application creation.
  # Any redirect URI is whitelisted by default.
  #
  # You can use this option in order to forbid URI's with 'javascript' scheme
  # for example.
  #
  # forbid_redirect_uri { |uri| uri.scheme.to_s.downcase == 'javascript' }

  # Specify how authorization errors should be handled.
  # By default, doorkeeper renders json errors when access token
  # is invalid, expired, revoked or has invalid scopes.
  #
  # If you want to render error response yourself (i.e. rescue exceptions),
  # set  handle_auth_errors to `:raise` and rescue Doorkeeper::Errors::InvalidToken
  # or following specific errors:
  #
  #   Doorkeeper::Errors::TokenForbidden, Doorkeeper::Errors::TokenExpired,
  #   Doorkeeper::Errors::TokenRevoked, Doorkeeper::Errors::TokenUnknown
  #
  # handle_auth_errors :raise

  # Specify what grant flows are enabled in array of Strings. The valid
  # strings and the flows they enable are:
  #
  # "authorization_code" => Authorization Code Grant Flow
  # "implicit"           => Implicit Grant Flow
  # "password"           => Resource Owner Password Credentials Grant Flow
  # "client_credentials" => Client Credentials Grant Flow
  #
  # If not specified, Doorkeeper enables authorization_code and
  # client_credentials.
  #
  # implicit and password grant flows have risks that you should understand
  # before enabling:
  #   http://tools.ietf.org/html/rfc6819#section-4.4.2
  #   http://tools.ietf.org/html/rfc6819#section-4.4.3
  #
  # grant_flows %w[authorization_code client_credentials]

  # Hook into the strategies' request & response life-cycle in case your
  # application needs advanced customization or logging:
  #
  # before_successful_strategy_response do |request|
  #   puts "BEFORE HOOK FIRED! #{request}"
  # end
  #
  # after_successful_strategy_response do |request, response|
  #   puts "AFTER HOOK FIRED! #{request}, #{response}"
  # end

  # Hook into Authorization flow in order to implement Single Sign Out
  # or add ny other functionality.
  #
  # before_successful_authorization do |controller|
  #   Rails.logger.info(params.inspect)
  # end
  #
  after_successful_authorization do |controller|
    # Schedule a cleanup job to clean out over-TTL tokens and grants
    ::OAuth::CleanupJob.perform_later
  end

  # Under some circumstances you might want to have applications auto-approved,
  # so that the user skips the authorization step.
  # For example if dealing with a trusted application.
  #
  # skip_authorization do |resource_owner, client|
  #   client.superapp? or resource_owner.admin?
  # end

  # WWW-Authenticate Realm (default "Doorkeeper").
  #
  # realm "Doorkeeper"
end

OpenProject::Application.configure do |application|
  application.config.to_prepare do
    # Requiring some classes of Doorkeeper ourselves which for whatever reasons are
    # no longer loaded for us now that we use zeitwerk
    require 'doorkeeper/application_metal_controller'
    require 'doorkeeper/application_controller'
    require 'doorkeeper/tokens_controller'
    require 'doorkeeper/authorizations_controller'
  end
end
