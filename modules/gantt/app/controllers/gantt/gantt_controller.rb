module ::Gantt
  class GanttController < ApplicationController
    include Layout
    include QueriesHelper
    include WorkPackagesControllerHelper

    accept_key_auth :index

    before_action :load_and_authorize_in_optional_project, :protect_from_unauthorized_export, only: :index

    before_action :load_and_validate_query, only: :index, unless: -> { request.format.html? }

    menu_item :gantt
    def index
      # If there are no query_props given, redirect to the default query
      if params[:query_props].nil? && params[:query_id].nil?
        if @project.present?
          return redirect_to(
            project_gantt_index_path(
              @project,
              ::Gantt::DefaultQueryGeneratorService.new(with_project: @project).call
            )
          )
        else
          return redirect_to(
            gantt_index_path(Gantt::DefaultQueryGeneratorService.new(with_project: nil).call)
          )
        end
      end

      respond_to do |format|
        format.html do
          render :index,
                 locals: { query: @query, project: @project, menu_name: project_or_global_menu },
                 layout: "angular/angular"
        end

        format.any(*supported_list_formats) do
          export_list(request.format.symbol)
        end

        format.atom do
          atom_list
        end
      end
    end

    private

    def default_breadcrumb
      t(:label_gantt_chart_plural)
    end
  end
end
