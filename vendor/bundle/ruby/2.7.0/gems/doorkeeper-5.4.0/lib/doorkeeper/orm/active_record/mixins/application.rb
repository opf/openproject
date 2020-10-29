# frozen_string_literal: true

module Doorkeeper::Orm::ActiveRecord::Mixins
  module Application
    extend ActiveSupport::Concern

    included do
      self.table_name = "#{table_name_prefix}oauth_applications#{table_name_suffix}"

      include ::Doorkeeper::ApplicationMixin

      has_many :access_grants,
               foreign_key: :application_id,
               dependent: :delete_all,
               class_name: Doorkeeper.config.access_grant_class.to_s

      has_many :access_tokens,
               foreign_key: :application_id,
               dependent: :delete_all,
               class_name: Doorkeeper.config.access_token_class.to_s

      validates :name, :secret, :uid, presence: true
      validates :uid, uniqueness: { case_sensitive: true }
      validates :redirect_uri, "doorkeeper/redirect_uri": true
      validates :confidential, inclusion: { in: [true, false] }

      validate :scopes_match_configured, if: :enforce_scopes?

      before_validation :generate_uid, :generate_secret, on: :create

      has_many :authorized_tokens,
               -> { where(revoked_at: nil) },
               foreign_key: :application_id,
               class_name: Doorkeeper.config.access_token_class.to_s

      has_many :authorized_applications,
               through: :authorized_tokens,
               source: :application

      # Generates a new secret for this application, intended to be used
      # for rotating the secret or in case of compromise.
      #
      # @return [String] new transformed secret value
      #
      def renew_secret
        @raw_secret = Doorkeeper::OAuth::Helpers::UniqueToken.generate
        secret_strategy.store_secret(self, :secret, @raw_secret)
      end

      # We keep a volatile copy of the raw secret for initial communication
      # The stored refresh_token may be mapped and not available in cleartext.
      #
      # Some strategies allow restoring stored secrets (e.g. symmetric encryption)
      # while hashing strategies do not, so you cannot rely on this value
      # returning a present value for persisted tokens.
      def plaintext_secret
        if secret_strategy.allows_restoring_secrets?
          secret_strategy.restore_secret(self, :secret)
        else
          @raw_secret
        end
      end

      # Represents client as set of it's attributes in JSON format.
      # This is the right way how we want to override ActiveRecord #to_json.
      #
      # Respects privacy settings and serializes minimum set of attributes
      # for public/private clients and full set for authorized owners.
      #
      # @return [Hash] entity attributes for JSON
      #
      def as_json(options = {})
        # if application belongs to some owner we need to check if it's the same as
        # the one passed in the options or check if we render the client as an owner
        if (respond_to?(:owner) && owner && owner == options[:current_resource_owner]) ||
           options[:as_owner]
          # Owners can see all the client attributes, fallback to ActiveModel serialization
          super
        else
          # if application has no owner or it's owner doesn't match one from the options
          # we render only minimum set of attributes that could be exposed to a public
          only = extract_serializable_attributes(options)
          super(options.merge(only: only))
        end
      end

      def authorized_for_resource_owner?(resource_owner)
        Doorkeeper.configuration.authorize_resource_owner_for_client.call(self, resource_owner)
      end

      # We need to hook into this method to allow serializing plan-text secrets
      # when secrets hashing enabled.
      #
      # @param key [String] attribute name
      #
      def read_attribute_for_serialization(key)
        return super unless key.to_s == "secret"

        plaintext_secret || secret
      end

      private

      def generate_uid
        self.uid = Doorkeeper::OAuth::Helpers::UniqueToken.generate if uid.blank?
      end

      def generate_secret
        return if secret.present?

        renew_secret
      end

      def scopes_match_configured
        if scopes.present? && !Doorkeeper::OAuth::Helpers::ScopeChecker.valid?(
          scope_str: scopes.to_s,
          server_scopes: Doorkeeper.config.scopes,
        )
          errors.add(:scopes, :not_match_configured)
        end
      end

      def enforce_scopes?
        Doorkeeper.config.enforce_configured_scopes?
      end

      # Helper method to extract collection of serializable attribute names
      # considering serialization options (like `only`, `except` and so on).
      #
      # @param options [Hash] serialization options
      #
      # @return [Array<String>]
      #   collection of attributes to be serialized using #as_json
      #
      def extract_serializable_attributes(options = {})
        opts = options.try(:dup) || {}
        only = Array.wrap(opts[:only]).map(&:to_s)

        only = if only.blank?
                 serializable_attributes
               else
                 only & serializable_attributes
               end

        only -= Array.wrap(opts[:except]).map(&:to_s) if opts.key?(:except)
        only.uniq
      end

      # Collection of attributes that could be serialized for public.
      # Override this method if you need additional attributes to be serialized.
      #
      # @return [Array<String>] collection of serializable attributes
      def serializable_attributes
        attributes = %w[id name created_at]
        attributes << "uid" unless confidential?
        attributes
      end
    end

    module ClassMethods
      # Returns Applications associated with active (not revoked) Access Tokens
      # that are owned by the specific Resource Owner.
      #
      # @param resource_owner [ActiveRecord::Base]
      #   Resource Owner model instance
      #
      # @return [ActiveRecord::Relation]
      #   Applications authorized for the Resource Owner
      #
      def authorized_for(resource_owner)
        resource_access_tokens = Doorkeeper.config.access_token_model.active_for(resource_owner)
        where(id: resource_access_tokens.select(:application_id).distinct)
      end

      # Revokes AccessToken and AccessGrant records that have not been revoked and
      # associated with the specific Application and Resource Owner.
      #
      # @param resource_owner [ActiveRecord::Base]
      #   instance of the Resource Owner model
      #
      def revoke_tokens_and_grants_for(id, resource_owner)
        Doorkeeper.config.access_token_model.revoke_all_for(id, resource_owner)
        Doorkeeper.config.access_grant_model.revoke_all_for(id, resource_owner)
      end
    end
  end
end
