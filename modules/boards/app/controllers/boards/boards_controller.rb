module ::Boards
  class BoardsController < BaseController
    include OpenProject::ClientPreferenceExtractor
    before_action :find_project_by_project_id
    menu_item :board_view

    def index
      gon.settings = client_preferences
      render layout: 'angular'
    end
  end
end
