module ::Dashboards
  class DashboardsController < ::ApplicationController
    before_action :find_optional_project
    before_action :authorize

    menu_item :dashboards

    def show
      render layout: 'angular'
    end
  end
end
