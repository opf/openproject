# frozen_string_literal: true

module RiskManagement
  class MenusController < ApplicationController
    before_action :find_project_by_project_id
    authorize_with_permission :view_risk_log

    def show
      @submenu_menu_items = RiskManagement::Menu.new(project: @project, params:).menu_items
      render layout: nil
    end
  end
end
