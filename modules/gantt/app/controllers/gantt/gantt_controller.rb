module ::Gantt
  class GanttController < ApplicationController
    include Layout
    include WorkPackagesControllerHelper

    accept_key_auth :index

    before_action :find_optional_project, :protect_from_unauthorized_export, only: :index

    before_action :load_and_validate_query, only: :index, unless: -> { request.format.html? }

    menu_item :gantt
    def index
      respond_to do |format|
        format.html do
          render :index,
                 locals: { query: @query, project: @project, menu_name: project_or_global_menu },
                 layout: 'angular/angular'
        end

        format.any(*supported_list_formats) do
          export_list(request.format.symbol)
        end

        format.atom do
          atom_list
        end
      end
    end
  end
end
