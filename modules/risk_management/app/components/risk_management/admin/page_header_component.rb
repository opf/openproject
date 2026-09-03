# frozen_string_literal: true

module RiskManagement
  module Admin
    class PageHeaderComponent < ApplicationComponent
      def breadcrumb_items
        [
          { href: admin_index_path, text: t(:label_administration) },
          { href: admin_settings_work_packages_general_path, text: t(:label_work_package_plural) },
          t("risk_management.label")
        ]
      end
    end
  end
end
