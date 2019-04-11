module ::Boards
  class BoardsController < BaseController
    include OpenProject::ClientPreferenceExtractor

    before_action :find_optional_project
    before_action :authorize

    # The boards permission alone does not suffice
    # to view work packages
    before_action :authorize_work_package_permission

    # Pass some visibility settings via gon that are not
    # available through the global grids API
    before_action :pass_gon

    menu_item :board_view

    def index
      render layout: 'angular'
    end

    current_menu_item :index do
      :board_view
    end

    private

    def pass_gon
      gon.settings = client_preferences
    end

    def authorize_work_package_permission
      unless current_user.allowed_to?(:view_work_packages, @project, global: @project.nil?)
        deny_access
      end
    end
  end
end
