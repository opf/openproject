# frozen_string_literal: true

module Doorkeeper
  module Models
    ##
    # Storable finder to provide lookups for input plaintext values which are
    # mapped to their stored versions (e.g., hashing, encryption) before lookup.
    module SecretStorable
      extend ActiveSupport::Concern

      delegate :secret_strategy,
               :fallback_secret_strategy,
               to: :class

      # :nodoc
      module ClassMethods
        # Compare the given plaintext with the secret
        #
        # @param input [String]
        #   The plain input to compare.
        #
        # @param secret [String]
        #   The secret value to compare with.
        #
        # @return [Boolean]
        #   Whether input matches secret as per the secret strategy
        #
        delegate :secret_matches?, to: :secret_strategy

        # Returns an instance of the Doorkeeper::AccessToken with
        # specific token value.
        #
        # @param attr [Symbol]
        #   The token attribute we're looking with.
        #
        # @param token [#to_s]
        #   token value (any object that responds to `#to_s`)
        #
        # @return [Doorkeeper::AccessToken, nil] AccessToken object or nil
        #   if there is no record with such token
        #
        def find_by_plaintext_token(attr, token)
          token = token.to_s

          find_by(attr => secret_strategy.transform_secret(token)) ||
            find_by_fallback_token(attr, token)
        end

        # Allow looking up previously plain tokens as a fallback
        # IFF a fallback strategy has been defined
        #
        # @param attr [Symbol]
        #   The token attribute we're looking with.
        #
        # @param plain_secret [#to_s]
        #   plain secret value (any object that responds to `#to_s`)
        #
        # @return [Doorkeeper::AccessToken, nil] AccessToken object or nil
        #   if there is no record with such token
        #
        def find_by_fallback_token(attr, plain_secret)
          return nil unless fallback_secret_strategy

          # Use the previous strategy to look up
          stored_token = fallback_secret_strategy.transform_secret(plain_secret)
          find_by(attr => stored_token).tap do |resource|
            return nil unless resource

            upgrade_fallback_value resource, attr, plain_secret
          end
        end

        # Allow implementations in ORMs to replace a plain
        # value falling back to to avoid it remaining as plain text.
        #
        # @param instance
        #   An instance of this model with a plain value token.
        #
        # @param attr
        #   The secret attribute name to upgrade.
        #
        # @param plain_secret
        #   The plain secret to upgrade.
        #
        def upgrade_fallback_value(instance, attr, plain_secret)
          upgraded = secret_strategy.store_secret(instance, attr, plain_secret)
          instance.update(attr => upgraded)
        end

        ##
        # Determines the secret storing transformer
        # Unless configured otherwise, uses the plain secret strategy
        def secret_strategy
          ::Doorkeeper::SecretStoring::Plain
        end

        ##
        # Determine the fallback storing strategy
        # Unless configured, there will be no fallback
        def fallback_secret_strategy
          nil
        end
      end
    end
  end
end
