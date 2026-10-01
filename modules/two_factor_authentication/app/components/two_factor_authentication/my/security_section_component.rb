# frozen_string_literal: true

module ::TwoFactorAuthentication
  module My
    class SecuritySectionComponent < ViewComponent::Base
      def initialize(user:, cookies:)
        @user = user
        @cookies = cookies

        super()
      end

      def render?
        strategy_manager.enabled?
      end

      def before_render
        @default_device = @user.otp_devices.get_default
        @two_factor_devices = @user.otp_devices.reload
        @available_devices = strategy_manager.available_devices
        @has_remember_token_for_user = any_remember_token_present?
        @remember_token = current_remember_token
      end

      private

      def strategy_manager
        ::OpenProject::TwoFactorAuthentication::TokenStrategyManager
      end

      def any_remember_token_present?
        return false unless remember_2fa_enabled?

        ::TwoFactorAuthentication::RememberedAuthToken.not_expired.exists?(user: @user)
      end

      def current_remember_token
        return false unless remember_2fa_enabled?

        value = @cookies.encrypted[:op2fa_remember_token]
        return false if value.blank?

        ::TwoFactorAuthentication::RememberedAuthToken.where(user: @user).find_by_plaintext_value(value)
      end

      def remember_2fa_enabled?
        strategy_manager.allow_remember_for_days > 0
      end
    end
  end
end
