module ::TwoFactorAuthentication
  module My
    class BackupCodesController < ::ApplicationController
      # Ensure user is logged in
      before_action :require_login

      # Password confirmation helpers and actions
      include PasswordConfirmation
      before_action :check_password_confirmation, only: [:create]

      # Verify that flash was set (coming from create)
      before_action :check_regenerate_done, only: [:show]

      layout 'my'
      menu_item :two_factor_authentication

      def create
        flash[:_backup_codes] = TwoFactorAuthentication::BackupCode.regenerate!(current_user)
        redirect_to action: :show
      end

      def show
        render
      end

      def check_regenerate_done
        @backup_codes = flash[:_backup_codes]
        flash.delete :_backup_codes

        unless @backup_codes.present?
          flash[:error] = I18n.t(:notice_bad_request)
          redirect_to my_2fa_devices_path
        end
      end
    end
  end
end
