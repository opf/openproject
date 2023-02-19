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

    def settings_params
      settings = super
      settings[:working_days] = settings[:working_days].compact_blank.map(&:to_i).uniq
      settings
    end

    def contract_options
      { params_contract: Settings::WorkingDaysParamsContract }
    end
  end
end
