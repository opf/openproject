# frozen_string_literal: true

module Doorkeeper
  module SecretStoring
    ##
    # Plain text secret storing, which is the default
    # but also provides fallback lookup if
    # other secret storing mechanisms are enabled.
    class BCrypt < Base
      ##
      # Return the value to be stored by the database
      # @param plain_secret The plain secret input / generated
      def self.transform_secret(plain_secret)
        ::BCrypt::Password.create(plain_secret.to_s)
      end

      ##
      # Securely compare the given +input+ value with a +stored+ value
      # processed by +transform_secret+.
      def self.secret_matches?(input, stored)
        ::BCrypt::Password.new(stored.to_s) == input.to_s
      rescue ::BCrypt::Errors::InvalidHash
        false
      end

      ##
      # Determines whether this strategy supports restoring
      # secrets from the database. This allows detecting users
      # trying to use a non-restorable strategy with +reuse_access_tokens+.
      def self.allows_restoring_secrets?
        false
      end

      ##
      # Determines what secrets this strategy is applicable for
      def self.validate_for(model)
        unless model.to_sym == :application
          raise ArgumentError,
                "'#{name}' can only be used for storing application secrets."
        end

        unless bcrypt_present?
          raise ArgumentError,
                "'#{name}' requires the 'bcrypt' gem being loaded."
        end

        true
      end

      ##
      # Test if we can require the BCrypt gem
      def self.bcrypt_present?
        require "bcrypt"
        true
      rescue LoadError
        false
      end
    end
  end
end
