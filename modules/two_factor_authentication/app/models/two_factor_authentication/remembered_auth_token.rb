require_dependency 'token/hashed_token'
require_dependency 'token/expirable_token'

module TwoFactorAuthentication
  class RememberedAuthToken < ::Token::HashedToken
    include ::Token::ExpirableToken

    validate :validate_remember_time

    def self.validity_time
      allow_remember_for_days.days
    end

    protected

    ##
    # Potentially multiple sessions may exist
    # for a user with remember tokens set.
    # (e.g., two different browsers)
    def single_value?
      false
    end

    private

    def validate_remember_time
      unless self.class.allow_remember_for_days > 0
        errors.add :base, 'Invalid remember time'
      end
    end

    def self.allow_remember_for_days
      manager.allow_remember_for_days
    end

    def self.manager
      OpenProject::TwoFactorAuthentication::TokenStrategyManager
    end
  end
end
