module ::Overviews
  class OverviewsController < ::Grids::BaseInProjectController
    before_action :jump_to_project_menu_item

    menu_item :overview

    def jump_to_project_menu_item
      if params[:jump]
        # try to redirect to the requested menu item
        redirect_to_project_menu_item(@project, params[:jump]) && return
      end
    end
  end
end
