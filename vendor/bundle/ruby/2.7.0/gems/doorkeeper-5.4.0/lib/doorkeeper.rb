# frozen_string_literal: true

require "doorkeeper/config"
require "doorkeeper/engine"

# Main Doorkeeper namespace.
#
module Doorkeeper
  autoload :Errors, "doorkeeper/errors"
  autoload :OAuth, "doorkeeper/oauth"
  autoload :Rake, "doorkeeper/rake"
  autoload :Request, "doorkeeper/request"
  autoload :Server, "doorkeeper/server"
  autoload :StaleRecordsCleaner, "doorkeeper/stale_records_cleaner"
  autoload :Validations, "doorkeeper/validations"
  autoload :VERSION, "doorkeeper/version"

  autoload :AccessGrantMixin, "doorkeeper/models/access_grant_mixin"
  autoload :AccessTokenMixin, "doorkeeper/models/access_token_mixin"
  autoload :ApplicationMixin, "doorkeeper/models/application_mixin"

  module Helpers
    autoload :Controller, "doorkeeper/helpers/controller"
  end

  module Request
    autoload :Strategy, "doorkeeper/request/strategy"
    autoload :AuthorizationCode, "doorkeeper/request/authorization_code"
    autoload :ClientCredentials, "doorkeeper/request/client_credentials"
    autoload :Code, "doorkeeper/request/code"
    autoload :Password, "doorkeeper/request/password"
    autoload :RefreshToken, "doorkeeper/request/refresh_token"
    autoload :Token, "doorkeeper/request/token"
  end

  module OAuth
    autoload :BaseRequest, "doorkeeper/oauth/base_request"
    autoload :AuthorizationCodeRequest, "doorkeeper/oauth/authorization_code_request"
    autoload :BaseResponse, "doorkeeper/oauth/base_response"
    autoload :CodeResponse, "doorkeeper/oauth/code_response"
    autoload :Client, "doorkeeper/oauth/client"
    autoload :ClientCredentialsRequest, "doorkeeper/oauth/client_credentials_request"
    autoload :CodeRequest, "doorkeeper/oauth/code_request"
    autoload :ErrorResponse, "doorkeeper/oauth/error_response"
    autoload :Error, "doorkeeper/oauth/error"
    autoload :InvalidTokenResponse, "doorkeeper/oauth/invalid_token_response"
    autoload :InvalidRequestResponse, "doorkeeper/oauth/invalid_request_response"
    autoload :ForbiddenTokenResponse, "doorkeeper/oauth/forbidden_token_response"
    autoload :NonStandard, "doorkeeper/oauth/nonstandard"
    autoload :PasswordAccessTokenRequest, "doorkeeper/oauth/password_access_token_request"
    autoload :PreAuthorization, "doorkeeper/oauth/pre_authorization"
    autoload :RefreshTokenRequest, "doorkeeper/oauth/refresh_token_request"
    autoload :Scopes, "doorkeeper/oauth/scopes"
    autoload :Token, "doorkeeper/oauth/token"
    autoload :TokenIntrospection, "doorkeeper/oauth/token_introspection"
    autoload :TokenRequest, "doorkeeper/oauth/token_request"
    autoload :TokenResponse, "doorkeeper/oauth/token_response"

    module Authorization
      autoload :Code, "doorkeeper/oauth/authorization/code"
      autoload :Context, "doorkeeper/oauth/authorization/context"
      autoload :Token, "doorkeeper/oauth/authorization/token"
      autoload :URIBuilder, "doorkeeper/oauth/authorization/uri_builder"
    end

    class Client
      autoload :Credentials, "doorkeeper/oauth/client/credentials"
    end

    module ClientCredentials
      autoload :Validator, "doorkeeper/oauth/client_credentials/validator"
      autoload :Creator, "doorkeeper/oauth/client_credentials/creator"
      autoload :Issuer, "doorkeeper/oauth/client_credentials/issuer"
    end

    module Helpers
      autoload :ScopeChecker, "doorkeeper/oauth/helpers/scope_checker"
      autoload :URIChecker, "doorkeeper/oauth/helpers/uri_checker"
      autoload :UniqueToken, "doorkeeper/oauth/helpers/unique_token"
    end

    module Hooks
      autoload :Context, "doorkeeper/oauth/hooks/context"
    end
  end

  module Models
    autoload :Accessible, "doorkeeper/models/concerns/accessible"
    autoload :Expirable, "doorkeeper/models/concerns/expirable"
    autoload :Orderable, "doorkeeper/models/concerns/orderable"
    autoload :Scopes, "doorkeeper/models/concerns/scopes"
    autoload :Reusable, "doorkeeper/models/concerns/reusable"
    autoload :ResourceOwnerable, "doorkeeper/models/concerns/resource_ownerable"
    autoload :Revocable, "doorkeeper/models/concerns/revocable"
    autoload :SecretStorable, "doorkeeper/models/concerns/secret_storable"
  end

  module Orm
    autoload :ActiveRecord, "doorkeeper/orm/active_record"
  end

  module Rails
    autoload :Helpers, "doorkeeper/rails/helpers"
    autoload :Routes, "doorkeeper/rails/routes"
  end

  module SecretStoring
    autoload :Base, "doorkeeper/secret_storing/base"
    autoload :Plain, "doorkeeper/secret_storing/plain"
    autoload :Sha256Hash, "doorkeeper/secret_storing/sha256_hash"
    autoload :BCrypt, "doorkeeper/secret_storing/bcrypt"
  end

  def self.authenticate(request, methods = Doorkeeper.config.access_token_methods)
    OAuth::Token.authenticate(request, *methods)
  end
end
