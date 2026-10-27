# frozen_string_literal: true

module RiskManagement
  module Patches
    module WorkPackagesDialogsCreateDialogComponent
      def dialog_title
        return super unless risk_work_package?

        I18n.t("risk_management.risk_log.create_dialog.title")
      end

      private

      def risk_work_package?
        configuration = ::RiskManagement::Configuration.load
        configuration.valid? && work_package.type_id == configuration.risk_type_id
      end
    end
  end
end
