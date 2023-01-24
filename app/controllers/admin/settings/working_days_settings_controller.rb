module Admin::Settings
  class WorkingDaysSettingsController < ::Admin::SettingsController
    current_menu_item [:show] do
      :working_days
    end

    def default_breadcrumb
      t(:label_working_days)
    end

    def show_local_breadcrumb
      true
    end

    def failure_callback(call)
      @modified_non_working_days = call.result
      flash[:error] = call.message || I18n.t(:notice_internal_server_error)
      render action: 'show', tab: params[:tab]
    end

    protected

    def settings_params
      settings = super
      settings[:working_days] = working_days_params(settings)
      settings[:non_working_days] = non_working_days_params
      settings
    end

    def update_service
      ::Settings::WorkingDaysUpdateService
    end

    private

    def working_days_params(settings)
      settings[:working_days] ? settings[:working_days].compact_blank.map(&:to_i).uniq : []
    end

    def non_working_days_params
      non_working_days = params[:settings].to_unsafe_hash[:non_working_days] || {}
      non_working_days.to_h.values
    end
  end
end
