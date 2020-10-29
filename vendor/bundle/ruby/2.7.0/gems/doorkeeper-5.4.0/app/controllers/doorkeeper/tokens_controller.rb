# frozen_string_literal: true

module Doorkeeper
  class TokensController < Doorkeeper::ApplicationMetalController
    def create
      headers.merge!(authorize_response.headers)
      render json: authorize_response.body,
             status: authorize_response.status
    rescue Errors::DoorkeeperError => e
      handle_token_exception(e)
    end

    # OAuth 2.0 Token Revocation - http://tools.ietf.org/html/rfc7009
    def revoke
      # @see 2.1.  Revocation Request
      #
      #  The client constructs the request by including the following
      #  parameters using the "application/x-www-form-urlencoded" format in
      #  the HTTP request entity-body:
      #     token   REQUIRED.
      #     token_type_hint  OPTIONAL.
      #
      #  The client also includes its authentication credentials as described
      #  in Section 2.3. of [RFC6749].
      #
      #  The authorization server first validates the client credentials (in
      #  case of a confidential client) and then verifies whether the token
      #  was issued to the client making the revocation request.
      unless server.client
        # If this validation [client credentials / token ownership] fails, the request is
        # refused and the  client is informed of the error by the authorization server as
        # described below.
        #
        # @see 2.2.1.  Error Response
        #
        # The error presentation conforms to the definition in Section 5.2 of [RFC6749].
        render json: revocation_error_response, status: :forbidden
        return
      end

      # The authorization server responds with HTTP status code 200 if the client
      # submitted an invalid token or the token has been revoked successfully.
      if token.blank?
        render json: {}, status: 200
      # The authorization server validates [...] and whether the token
      # was issued to the client making the revocation request. If this
      # validation fails, the request is refused and the client is informed
      # of the error by the authorization server as described below.
      elsif authorized?
        revoke_token
        render json: {}, status: 200
      else
        render json: revocation_error_response, status: :forbidden
      end
    end

    def introspect
      introspection = OAuth::TokenIntrospection.new(server, token)

      if introspection.authorized?
        render json: introspection.to_json, status: 200
      else
        error = introspection.error_response
        headers.merge!(error.headers)
        render json: error.body, status: error.status
      end
    end

    private

    # OAuth 2.0 Section 2.1 defines two client types, "public" & "confidential".
    # A malicious client may attempt to guess valid tokens on this endpoint
    # by making revocation requests against potential token strings.
    # According to this specification, a client's request must contain a
    # valid client_id, in the case of a public client, or valid client
    # credentials, in the case of a confidential client. The token being
    # revoked must also belong to the requesting client.
    #
    # Once a confidential client is authenticated, it must be authorized to
    # revoke the provided access or refresh token. This ensures one client
    # cannot revoke another's tokens.
    #
    # Doorkeeper determines the client type implicitly via the presence of the
    # OAuth client associated with a given access or refresh token. Since public
    # clients authenticate the resource owner via "password" or "implicit" grant
    # types, they set the application_id as null (since the claim cannot be
    # verified).
    #
    # https://tools.ietf.org/html/rfc6749#section-2.1
    # https://tools.ietf.org/html/rfc7009
    def authorized?
      # Token belongs to specific client, so we need to check if
      # authenticated client could access it.
      if token.application_id? && token.application.confidential?
        # We authorize client by checking token's application
        server.client && server.client.application == token.application
      else
        # Token was issued without client, authorization unnecessary
        true
      end
    end

    def revoke_token
      # The authorization server responds with HTTP status code 200 if the token
      # has been revoked successfully or if the client submitted an invalid
      # token
      token.revoke if token&.accessible?
    end

    # Doorkeeper does not use the token_type_hint logic described in the
    # RFC 7009 due to the refresh token implementation that is a field in
    # the access token model.
    def token
      @token ||= Doorkeeper.config.access_token_model.by_token(params["token"]) ||
                 Doorkeeper.config.access_token_model.by_refresh_token(params["token"])
    end

    def strategy
      @strategy ||= server.token_request(params[:grant_type])
    end

    def authorize_response
      @authorize_response ||= begin
        before_successful_authorization
        auth = strategy.authorize
        context = build_context(auth: auth)
        after_successful_authorization(context) unless auth.is_a?(Doorkeeper::OAuth::ErrorResponse)
        auth
      end
    end

    def build_context(**attributes)
      Doorkeeper::OAuth::Hooks::Context.new(**attributes)
    end

    def before_successful_authorization(context = nil)
      Doorkeeper.config.before_successful_authorization.call(self, context)
    end

    def after_successful_authorization(context)
      Doorkeeper.config.after_successful_authorization.call(self, context)
    end

    def revocation_error_response
      error_description = I18n.t(:unauthorized, scope: %i[doorkeeper errors messages revoke])

      { error: :unauthorized_client, error_description: error_description }
    end
  end
end
