module ::Recaptcha
  class AdminController < ApplicationController
    include ::RecaptchaHelper

    before_action :require_admin
    before_action :validate_settings, only: :update
    layout 'admin'

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
      allowed_options = recaptcha_available_options.map(&:last)

      unless allowed_options.include? new_params[:recaptcha_type]
        flash[:error] = I18n.t(:error_code, code: '400')
        redirect_to action: :show
        return
      end

      @settings = new_params.to_h.symbolize_keys
    end

    def permitted_params
      params.permit(:recaptcha_type, :website_key, :secret_key)
    end

    def default_breadcrumb
      t('recaptcha.label_recaptcha')
    end

    def show_local_breadcrumb
      true
    end
  end
end
