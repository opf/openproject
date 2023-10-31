module Ldap
  class PostLoginSyncService < BaseService
    attr_reader :user, :update_attributes

    def initialize(ldap, user:, attributes:)
      super(ldap)

      @user = user
      @update_attributes = attributes
    end

    private

    def perform
      synchronize_user_attributes(user, update_attributes)
    rescue StandardError => e
      Rails.logger.error { "Failed to synchronize user after login #{ldap.name}: #{e.message}" }
      ServiceResult.failure(message: "Failed to synchronize user #{user.login}: #{e.message}")
    end
  end
end
