# frozen_string_literal: true

module Doorkeeper
  module AccessTokenMixin
    extend ActiveSupport::Concern

    include OAuth::Helpers
    include Models::Expirable
    include Models::Reusable
    include Models::Revocable
    include Models::Accessible
    include Models::Orderable
    include Models::SecretStorable
    include Models::Scopes
    include Models::ResourceOwnerable

    module ClassMethods
      # Returns an instance of the Doorkeeper::AccessToken with
      # specific plain text token value.
      #
      # @param token [#to_s]
      #   Plain text token value (any object that responds to `#to_s`)
      #
      # @return [Doorkeeper::AccessToken, nil] AccessToken object or nil
      #   if there is no record with such token
      #
      def by_token(token)
        find_by_plaintext_token(:token, token)
      end

      # Returns an instance of the Doorkeeper::AccessToken
      # with specific token value.
      #
      # @param refresh_token [#to_s]
      #   refresh token value (any object that responds to `#to_s`)
      #
      # @return [Doorkeeper::AccessToken, nil] AccessToken object or nil
      #   if there is no record with such refresh token
      #
      def by_refresh_token(refresh_token)
        find_by_plaintext_token(:refresh_token, refresh_token)
      end

      # Returns an instance of the Doorkeeper::AccessToken
      # found by previous refresh token. Keep in mind that value
      # of the previous_refresh_token isn't encrypted using
      # secrets strategy.
      #
      # @param previous_refresh_token [#to_s]
      #   previous refresh token value (any object that responds to `#to_s`)
      #
      # @return [Doorkeeper::AccessToken, nil] AccessToken object or nil
      #   if there is no record with such refresh token
      #
      def by_previous_refresh_token(previous_refresh_token)
        find_by(refresh_token: previous_refresh_token)
      end

      # Revokes AccessToken records that have not been revoked and associated
      # with the specific Application and Resource Owner.
      #
      # @param application_id [Integer]
      #   ID of the Application
      # @param resource_owner [ActiveRecord::Base, Integer]
      #   instance of the Resource Owner model or it's ID
      #
      def revoke_all_for(application_id, resource_owner, clock = Time)
        by_resource_owner(resource_owner)
          .where(
            application_id: application_id,
            revoked_at: nil,
          )
          .update_all(revoked_at: clock.now.utc)
      end

      # Looking for not revoked Access Token with a matching set of scopes
      # that belongs to specific Application and Resource Owner.
      #
      # @param application [Doorkeeper::Application]
      #   Application instance
      # @param resource_owner [ActiveRecord::Base, Integer]
      #   Resource Owner model instance or it's ID
      # @param scopes [String, Doorkeeper::OAuth::Scopes]
      #   set of scopes
      #
      # @return [Doorkeeper::AccessToken, nil] Access Token instance or
      #   nil if matching record was not found
      #
      def matching_token_for(application, resource_owner, scopes)
        tokens = authorized_tokens_for(application&.id, resource_owner)
        find_matching_token(tokens, application, scopes)
      end

      # Interface to enumerate access token records in batches in order not
      # to bloat the memory. Could be overloaded in any ORM extension.
      #
      def find_access_token_in_batches(relation, *args, &block)
        relation.find_in_batches(*args, &block)
      end

      # Enumerates AccessToken records in batches to find a matching token.
      # Batching is required in order not to pollute the memory if Application
      # has huge amount of associated records.
      #
      # ActiveRecord 5.x - 6.x ignores custom ordering so we can't perform a
      # database sort by created_at, so we need to load all the matching records,
      # sort them and find latest one. Probably it would be better to rewrite this
      # query using Time math if possible, but we n eed to consider ORM and
      # different databases support.
      #
      # @param relation [ActiveRecord::Relation]
      #   Access tokens relation
      # @param application [Doorkeeper::Application]
      #   Application instance
      # @param scopes [String, Doorkeeper::OAuth::Scopes]
      #   set of scopes
      #
      # @return [Doorkeeper::AccessToken, nil] Access Token instance or
      #   nil if matching record was not found
      #
      def find_matching_token(relation, application, scopes)
        return nil unless relation

        matching_tokens = []
        batch_size = Doorkeeper.configuration.token_lookup_batch_size

        find_access_token_in_batches(relation, batch_size: batch_size) do |batch|
          tokens = batch.select do |token|
            scopes_match?(token.scopes, scopes, application&.scopes)
          end

          matching_tokens.concat(tokens)
        end

        matching_tokens.max_by(&:created_at)
      end

      # Checks whether the token scopes match the scopes from the parameters
      #
      # @param token_scopes [#to_s]
      #   set of scopes (any object that responds to `#to_s`)
      # @param param_scopes [Doorkeeper::OAuth::Scopes]
      #   scopes from params
      # @param app_scopes [Doorkeeper::OAuth::Scopes]
      #   Application scopes
      #
      # @return [Boolean] true if the param scopes match the token scopes,
      #   and all the param scopes are defined in the application (or in the
      #   server configuration if the application doesn't define any scopes),
      #   and false in other cases
      #
      def scopes_match?(token_scopes, param_scopes, app_scopes)
        return true if token_scopes.empty? && param_scopes.empty?

        (token_scopes.sort == param_scopes.sort) &&
          Doorkeeper::OAuth::Helpers::ScopeChecker.valid?(
            scope_str: param_scopes.to_s,
            server_scopes: Doorkeeper.config.scopes,
            app_scopes: app_scopes,
          )
      end

      # Looking for not expired AccessToken record with a matching set of
      # scopes that belongs to specific Application and Resource Owner.
      # If it doesn't exists - then creates it.
      #
      # @param application [Doorkeeper::Application]
      #   Application instance
      # @param resource_owner [ActiveRecord::Base, Integer]
      #   Resource Owner model instance or it's ID
      # @param scopes [#to_s]
      #   set of scopes (any object that responds to `#to_s`)
      # @param token_attributes [Hash]
      #   Additional attributes to use when creating a token
      # @option token_attributes [Integer] :expires_in
      #   token lifetime in seconds
      # @option token_attributes [Boolean] :use_refresh_token
      #   whether to use the refresh token
      #
      # @return [Doorkeeper::AccessToken] existing record or a new one
      #
      def find_or_create_for(application:, resource_owner:, scopes:, **token_attributes)
        if Doorkeeper.config.reuse_access_token
          access_token = matching_token_for(application, resource_owner, scopes)

          return access_token if access_token&.reusable?
        end

        create_for(
          application: application,
          resource_owner: resource_owner,
          scopes: scopes,
          **token_attributes,
        )
      end

      # Creates a not expired AccessToken record with a matching set of
      # scopes that belongs to specific Application and Resource Owner.
      #
      # @param application [Doorkeeper::Application]
      #   Application instance
      # @param resource_owner [ActiveRecord::Base, Integer]
      #   Resource Owner model instance or it's ID
      # @param scopes [#to_s]
      #   set of scopes (any object that responds to `#to_s`)
      # @param token_attributes [Hash]
      #   Additional attributes to use when creating a token
      # @option token_attributes [Integer] :expires_in
      #   token lifetime in seconds
      # @option token_attributes [Boolean] :use_refresh_token
      #   whether to use the refresh token
      #
      # @return [Doorkeeper::AccessToken] new access token
      #
      def create_for(application:, resource_owner:, scopes:, **token_attributes)
        token_attributes[:application_id] = application&.id
        token_attributes[:scopes] = scopes.to_s

        if Doorkeeper.config.polymorphic_resource_owner?
          token_attributes[:resource_owner] = resource_owner
        else
          token_attributes[:resource_owner_id] = resource_owner_id_for(resource_owner)
        end

        create!(token_attributes)
      end

      # Looking for not revoked Access Token records that belongs to specific
      # Application and Resource Owner.
      #
      # @param application_id [Integer]
      #   ID of the Application model instance
      # @param resource_owner [ActiveRecord::Base, Integer]
      #   Resource Owner model instance or it's ID
      #
      # @return [ActiveRecord::Relation]
      #   collection of matching AccessToken objects
      #
      def authorized_tokens_for(application_id, resource_owner)
        by_resource_owner(resource_owner).where(
          application_id: application_id,
          revoked_at: nil,
        )
      end

      # Convenience method for backwards-compatibility, return the last
      # matching token for the given Application and Resource Owner.
      #
      # @param application_id [Integer]
      #   ID of the Application model instance
      # @param resource_owner [ActiveRecord::Base, Integer]
      #   ID of the Resource Owner model instance
      #
      # @return [Doorkeeper::AccessToken, nil] matching AccessToken object or
      #   nil if nothing was found
      #
      def last_authorized_token_for(application_id, resource_owner)
        authorized_tokens_for(application_id, resource_owner)
          .ordered_by(:created_at, :desc)
          .first
      end

      ##
      # Determines the secret storing transformer
      # Unless configured otherwise, uses the plain secret strategy
      #
      # @return [Doorkeeper::SecretStoring::Base]
      #
      def secret_strategy
        ::Doorkeeper.config.token_secret_strategy
      end

      ##
      # Determine the fallback storing strategy
      # Unless configured, there will be no fallback
      def fallback_secret_strategy
        ::Doorkeeper.config.token_secret_fallback_strategy
      end
    end

    # Access Token type: Bearer.
    # @see https://tools.ietf.org/html/rfc6750
    #   The OAuth 2.0 Authorization Framework: Bearer Token Usage
    #
    def token_type
      "Bearer"
    end

    def use_refresh_token?
      @use_refresh_token ||= false
      !!@use_refresh_token
    end

    # JSON representation of the Access Token instance.
    #
    # @return [Hash] hash with token data
    def as_json(_options = {})
      {
        resource_owner_id: resource_owner_id,
        scope: scopes,
        expires_in: expires_in_seconds,
        application: { uid: application.try(:uid) },
        created_at: created_at.to_i,
      }.tap do |json|
        if Doorkeeper.configuration.polymorphic_resource_owner?
          json[:resource_owner_type] = resource_owner_type
        end
      end
    end

    # Indicates whether the token instance have the same credential
    # as the other Access Token.
    #
    # @param access_token [Doorkeeper::AccessToken] other token
    #
    # @return [Boolean] true if credentials are same of false in other cases
    #
    def same_credential?(access_token)
      application_id == access_token.application_id &&
        same_resource_owner?(access_token)
    end

    # Indicates whether the token instance have the same credential
    # as the other Access Token.
    #
    # @param access_token [Doorkeeper::AccessToken] other token
    #
    # @return [Boolean] true if credentials are same of false in other cases
    #
    def same_resource_owner?(access_token)
      if Doorkeeper.configuration.polymorphic_resource_owner?
        resource_owner == access_token.resource_owner
      else
        resource_owner_id == access_token.resource_owner_id
      end
    end

    # Indicates if token is acceptable for specific scopes.
    #
    # @param scopes [Array<String>] scopes
    #
    # @return [Boolean] true if record is accessible and includes scopes or
    #   false in other cases
    #
    def acceptable?(scopes)
      accessible? && includes_scope?(*scopes)
    end

    # We keep a volatile copy of the raw refresh token for initial communication
    # The stored refresh_token may be mapped and not available in cleartext.
    def plaintext_refresh_token
      if secret_strategy.allows_restoring_secrets?
        secret_strategy.restore_secret(self, :refresh_token)
      else
        @raw_refresh_token
      end
    end

    # We keep a volatile copy of the raw token for initial communication
    # The stored refresh_token may be mapped and not available in cleartext.
    #
    # Some strategies allow restoring stored secrets (e.g. symmetric encryption)
    # while hashing strategies do not, so you cannot rely on this value
    # returning a present value for persisted tokens.
    def plaintext_token
      if secret_strategy.allows_restoring_secrets?
        secret_strategy.restore_secret(self, :token)
      else
        @raw_token
      end
    end

    # Revokes token with `:refresh_token` equal to `:previous_refresh_token`
    # and clears `:previous_refresh_token` attribute.
    #
    def revoke_previous_refresh_token!
      return unless self.class.refresh_token_revoked_on_use?

      old_refresh_token&.revoke
      update_column(:previous_refresh_token, "")
    end

    private

    # Searches for Access Token record with `:refresh_token` equal to
    # `:previous_refresh_token` value.
    #
    # @return [Doorkeeper::AccessToken, nil]
    #   Access Token record or nil if nothing found
    #
    def old_refresh_token
      @old_refresh_token ||= self.class.by_previous_refresh_token(previous_refresh_token)
    end

    # Generates refresh token with UniqueToken generator.
    #
    # @return [String] refresh token value
    #
    def generate_refresh_token
      @raw_refresh_token = UniqueToken.generate
      secret_strategy.store_secret(self, :refresh_token, @raw_refresh_token)
    end

    # Generates and sets the token value with the
    # configured Generator class (see Doorkeeper.config).
    #
    # @return [String] generated token value
    #
    # @raise [Doorkeeper::Errors::UnableToGenerateToken]
    #   custom class doesn't implement .generate method
    # @raise [Doorkeeper::Errors::TokenGeneratorNotFound]
    #   custom class doesn't exist
    #
    def generate_token
      self.created_at ||= Time.now.utc

      @raw_token = token_generator.generate(attributes_for_token_generator)
      secret_strategy.store_secret(self, :token, @raw_token)
      @raw_token
    end

    # Set of attributes that would be passed to token generator to
    # generate unique token based on them.
    #
    #  @return [Hash] set of attributes
    #
    def attributes_for_token_generator
      {
        resource_owner_id: resource_owner_id,
        scopes: scopes,
        application: application,
        expires_in: expires_in,
        created_at: created_at,
      }.tap do |attributes|
        if Doorkeeper.config.polymorphic_resource_owner?
          attributes[:resource_owner] = resource_owner
        end
      end
    end

    def token_generator
      generator_name = Doorkeeper.config.access_token_generator
      generator = generator_name.constantize

      return generator if generator.respond_to?(:generate)

      raise Errors::UnableToGenerateToken, "#{generator} does not respond to `.generate`."
    rescue NameError
      raise Errors::TokenGeneratorNotFound, "#{generator_name} not found"
    end
  end
end
