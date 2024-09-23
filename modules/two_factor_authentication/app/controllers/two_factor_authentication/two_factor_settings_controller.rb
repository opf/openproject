module ::TwoFactorAuthentication
  class TwoFactorSettingsController < ApplicationController
    include EnterpriseTrialHelper
    before_action :require_admin
    before_action :check_enabled
    before_action :check_writable, only: :update

    layout "admin"
    menu_item :two_factor_authentication

    def show
      render template: "two_factor_authentication/settings",
             locals: {
               settings: Setting.plugin_openproject_two_factor_authentication,
               strategy_manager: manager,
               configuration: manager.configuration
             }
    end

    def update
      current_settings = Setting.plugin_openproject_two_factor_authentication
      begin
        merge_settings!(current_settings, permitted_params)
        manager.validate_configuration!
        flash[:notice] = I18n.t(:notice_successful_update)
      rescue ArgumentError => e
        Setting.plugin_openproject_two_factor_authentication = current_settings
        flash[:error] = I18n.t("two_factor_authentication.settings.failed_to_save_settings", message: e.message)
        Rails.logger.error "Failed to save 2FA settings: #{e.message}"
      end

      redirect_to action: :show
    end

    private

    def check_writable
      unless Setting.plugin_openproject_two_factor_authentication_writable?
        render_403 message: I18n.t("two_factor_authentication.notice_not_writable")
      end
    end

    def permitted_params
      params.require(:settings).permit(:enforced, :allow_remember_for_days)
    end

    def merge_settings!(current, permitted)
      Setting.plugin_openproject_two_factor_authentication = current.merge(
        enforced: !!permitted[:enforced],
        allow_remember_for_days: permitted[:allow_remember_for_days]
      )
    end

    def check_enabled
      render_403 unless manager.configurable_by_ui?
    end

    def manager
      ::OpenProject::TwoFactorAuthentication::TokenStrategyManager
    end

    def default_breadcrumb; end

    def show_local_breadcrumb
      false
    end
  end
end
