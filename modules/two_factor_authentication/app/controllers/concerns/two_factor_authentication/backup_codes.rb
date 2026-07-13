# frozen_string_literal: true

module ::TwoFactorAuthentication
  module BackupCodes
    extend ActiveSupport::Concern

    ##
    # Request user to enter backup code
    def enter_backup_code
      render
    end

    ##
    # Verify backup code
    def verify_backup_code
      code = params[:backup_code]
      return fail_login(t("two_factor_authentication.error_invalid_backup_code")) unless code.present?

      service = TwoFactorAuthentication::UseBackupCodeService.new user: @authenticated_user
      result = service.verify code
      if result.success?
        complete_stage_redirect
      else
        @authenticated_user.log_failed_login
        fail_login(t("two_factor_authentication.error_invalid_backup_code"))
      end
    end
  end
end
