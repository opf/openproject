# frozen_string_literal: true

module Doorkeeper
  module OAuth
    module Authorization
      class Token
        attr_reader :pre_auth, :resource_owner, :token

        class << self
          def build_context(pre_auth_or_oauth_client, grant_type, scopes)
            oauth_client = if pre_auth_or_oauth_client.respond_to?(:application)
                             pre_auth_or_oauth_client.application
                           elsif pre_auth_or_oauth_client.respond_to?(:client)
                             pre_auth_or_oauth_client.client
                           else
                             pre_auth_or_oauth_client
                           end

            Doorkeeper::OAuth::Authorization::Context.new(
              oauth_client,
              grant_type,
              scopes,
            )
          end

          def access_token_expires_in(configuration, context)
            if configuration.option_defined?(:custom_access_token_expires_in)
              expiration = configuration.custom_access_token_expires_in.call(context)
              return nil if expiration == Float::INFINITY

              expiration || configuration.access_token_expires_in
            else
              configuration.access_token_expires_in
            end
          end

          def refresh_token_enabled?(server, context)
            if server.refresh_token_enabled?.respond_to?(:call)
              server.refresh_token_enabled?.call(context)
            else
              !!server.refresh_token_enabled?
            end
          end
        end

        def initialize(pre_auth, resource_owner)
          @pre_auth       = pre_auth
          @resource_owner = resource_owner
        end

        def issue_token!
          return @token if defined?(@token)

          context = self.class.build_context(
            pre_auth.client,
            Doorkeeper::OAuth::IMPLICIT,
            pre_auth.scopes,
          )

          @token = Doorkeeper.config.access_token_model.find_or_create_for(
            application: pre_auth.client,
            resource_owner: resource_owner,
            scopes: pre_auth.scopes,
            expires_in: self.class.access_token_expires_in(Doorkeeper.config, context),
            use_refresh_token: false,
          )
        end

        def oob_redirect
          {
            controller: controller,
            action: :show,
            access_token: token.plaintext_token,
          }
        end

        private

        def controller
          @controller ||= begin
            mapping = Doorkeeper::Rails::Routes.mapping[:token_info] || {}
            mapping[:controllers] || "doorkeeper/token_info"
          end
        end
      end
    end
  end
end
