# frozen_string_literal: true

module RiskManagement
  class Menu
    include Rails.application.routes.url_helpers

    VIEWS = %i[
      attention without_mitigation without_owner not_evaluated newly_added occurred closed last_updated created_by_me
    ].freeze

    def initialize(project:, params:)
      @project = project
      @params = params
    end

    def menu_items
      [OpenProject::Menu::MenuGroup.new(header: nil, children: view_items)]
    end

    private

    attr_reader :project, :params

    def view_items
      VIEWS.map do |view|
        OpenProject::Menu::MenuItem.new(
          title: I18n.t("risk_management.risk_log.navigation.#{view}"),
          href: project_risk_log_path(project, view:),
          selected: params[:view] == view.to_s
        )
      end
    end
  end
end
