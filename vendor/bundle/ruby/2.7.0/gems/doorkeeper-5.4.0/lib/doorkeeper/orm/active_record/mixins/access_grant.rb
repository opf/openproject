# frozen_string_literal: true

module Doorkeeper::Orm::ActiveRecord::Mixins
  module AccessGrant
    extend ActiveSupport::Concern

    included do
      self.table_name = "#{table_name_prefix}oauth_access_grants#{table_name_suffix}"

      include ::Doorkeeper::AccessGrantMixin

      belongs_to :application, class_name: Doorkeeper.config.application_class.to_s,
                               optional: true,
                               inverse_of: :access_grants

      if Doorkeeper.config.polymorphic_resource_owner?
        belongs_to :resource_owner, polymorphic: true, optional: false
      else
        validates :resource_owner_id, presence: true
      end

      validates :application_id,
                :token,
                :expires_in,
                :redirect_uri,
                presence: true

      validates :token, uniqueness: { case_sensitive: true }

      before_validation :generate_token, on: :create

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

      private

      # Generates token value with UniqueToken class.
      #
      # @return [String] token value
      #
      def generate_token
        @raw_token = Doorkeeper::OAuth::Helpers::UniqueToken.generate
        secret_strategy.store_secret(self, :token, @raw_token)
      end
    end
  end
end
