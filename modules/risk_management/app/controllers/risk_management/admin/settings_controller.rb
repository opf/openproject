# frozen_string_literal: true

module RiskManagement
  module Admin
    class SettingsController < ApplicationController
      layout "admin"
      menu_item :risk_management_settings
      before_action :require_admin

      def show
        @configuration = Configuration.load
      end

      def update
        @configuration = Configuration.new(configuration_params)

        if @configuration.save
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_to risk_management_admin_settings_path
        else
          render :show, status: :unprocessable_entity
        end
      end

      private

      def configuration_params
        params.expect(
          risk_management_configuration: %i[
            impact_very_low_max
            impact_low_max
            impact_medium_max
            impact_high_max
          ]
        )
      end
    end
  end
end
