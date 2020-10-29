# frozen_string_literal: true

namespace :doorkeeper do
  namespace :db do
    desc "Removes stale data from doorkeeper related database tables"
    task cleanup: [
      "doorkeeper:db:cleanup:revoked_tokens",
      "doorkeeper:db:cleanup:expired_tokens",
      "doorkeeper:db:cleanup:revoked_grants",
      "doorkeeper:db:cleanup:expired_grants",
    ]

    namespace :cleanup do
      desc "Removes stale access tokens"
      task revoked_tokens: "doorkeeper:setup" do
        cleaner = Doorkeeper::StaleRecordsCleaner.new(Doorkeeper::AccessToken)
        cleaner.clean_revoked
      end

      desc "Removes expired (TTL passed) access tokens"
      task expired_tokens: "doorkeeper:setup" do
        expirable_tokens = Doorkeeper.config.access_token_model.where(refresh_token: nil)
        cleaner = Doorkeeper::StaleRecordsCleaner.new(expirable_tokens)
        cleaner.clean_expired(Doorkeeper.config.access_token_expires_in)
      end

      desc "Removes stale access grants"
      task revoked_grants: "doorkeeper:setup" do
        cleaner = Doorkeeper::StaleRecordsCleaner.new(Doorkeeper::AccessGrant)
        cleaner.clean_revoked
      end

      desc "Removes expired (TTL passed) access grants"
      task expired_grants: "doorkeeper:setup" do
        cleaner = Doorkeeper::StaleRecordsCleaner.new(Doorkeeper::AccessGrant)
        cleaner.clean_expired(Doorkeeper.config.authorization_code_expires_in)
      end
    end
  end
end
