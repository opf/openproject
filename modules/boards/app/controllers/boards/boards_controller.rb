module ::Boards
  class BoardsController < BaseController

    before_action :find_project_by_project_id

    menu_item :boards

    def index
    end
  end
end
