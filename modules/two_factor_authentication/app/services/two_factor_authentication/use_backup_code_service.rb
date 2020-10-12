module TwoFactorAuthentication
  class UseBackupCodeService
    attr_reader :user

    ##
    # Create a token service for the given user.
    def initialize(user:)
      @user = user
    end

    ##
    # Validate a backup code that was input by the user
    def verify(code)
      token = user.otp_backup_codes.find_by_plaintext_value(code)

      raise I18n.t('two_factor_authentication.error_invalid_backup_code') if token.nil?
      use_valid_token! token
    rescue => e
      Rails.logger.error "[2FA plugin] Error during backup code validation for user##{user.id}: #{e}"

      result = ServiceResult.new(success: false)
      result.errors.add(:base, e.message)

      result
    end

    private

    def use_valid_token!(token)
      token.destroy!

      Rails.logger.info { "[2FA plugin] User ##{user.id} has used backup code." }
      ServiceResult.new(success: true, result: token)
    end
  end
end