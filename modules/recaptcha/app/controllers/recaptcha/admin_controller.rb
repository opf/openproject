module ::Recaptcha
  class AdminController < ApplicationController
    before_action :require_admin
    before_action :validate_settings, only: :update
    layout "admin"

    menu_item :plugin_recaptcha

    def show; end

    def update
      Setting.plugin_openproject_recaptcha = @settings
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: :show
    end

    private

    def validate_settings
      new_params = permitted_params
      allowed_options = OpenProject::Recaptcha::Services::AVAILABLE.map(&:value)

      unless allowed_options.include? new_params[:recaptcha_type]
        flash[:error] = I18n.t(:error_code, code: "400")
        redirect_to action: :show
        return
      end

      @settings = new_params.to_h.symbolize_keys
    end

    def permitted_params
      params.fetch(:settings, {}).permit(:recaptcha_type, :website_key, :secret_key, :response_limit)
    end
  end
end
