module ::Gantt
  class GanttController < ApplicationController
    include Layout
    include QueriesHelper
    include WorkPackagesControllerHelper
    include WorkPackages::WithSplitView

    accept_key_auth :index

    before_action :load_and_authorize_in_optional_project, :protect_from_unauthorized_export,
                  only: %i[index split_view split_create]

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
                 locals: { query: @query, project: @project, menu_name: project_or_global_menu }
        end

        format.any(*supported_list_formats) do
          export_list(request.format.symbol)
        end

        format.atom do
          atom_list
        end
      end
    end

    def split_view
      respond_to do |format|
        format.html do
          if turbo_frame_request?
            render "work_packages/split_view", layout: false
          else
            render :index,
                   locals: { query: @query, project: @project, menu_name: project_or_global_menu }
          end
        end
      end
    end

    def split_create
      respond_to do |format|
        format.html do
          if turbo_frame_request?
            render "work_packages/split_create", layout: false
          else
            render :index,
                   locals: { query: @query, project: @project, menu_name: project_or_global_menu }
          end
        end
      end
    end

    private

    def split_view_base_route
      if @project
        project_gantt_index_path(@project, request.query_parameters)
      else
        gantt_index_path(request.query_parameters)
      end
    end
  end
end
