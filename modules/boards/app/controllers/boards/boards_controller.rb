# frozen_string_literal: true

module ::Boards
  class BoardsController < BaseController
    include Layout
    include WorkPackages::WithSplitView

    before_action :load_and_authorize_in_optional_project
    before_action :find_board_for_deletion, only: %i[destroy]
    before_action :find_board, only: %i[show split_view]

    # The boards permission alone does not suffice
    # to view work packages
    before_action :authorize_work_package_permission, only: %i[show split_view]

    before_action :build_board_grid, only: %i[new]
    before_action :load_query, only: %i[index]

    menu_item :boards

    def index
      render "index", locals: { menu_name: project_or_global_menu }
    end

    def show
      render
    end

    def split_view
      respond_to do |format|
        format.html do
          if turbo_frame_request?
            render "work_packages/split_view", layout: false
          else
            render :show
          end
        end
      end
    end

    def new; end

    def create
      service_result = service_call

      @board_grid = service_result.result

      if service_result.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to project_work_package_board_path(@project, @board_grid)
      else
        render action: :new, status: :unprocessable_entity
      end
    end

    def destroy
      @board_grid.destroy!

      flash[:notice] = I18n.t(:notice_successful_delete)

      respond_to do |format|
        format.json do
          render json: { redirect_url: project_work_package_boards_path(@project) }
        end
        format.html do
          redirect_to action: "index", project_id: @project, status: :see_other
        end
      end
    end

    private

    def split_view_base_route
      project_work_package_board_path(@project, params[:id], request.query_parameters)
    end

    def load_query
      projects = @project || Project.allowed_to(User.current, :show_board_views)

      @board_grids = Boards::Grid.includes(:project)
                                 .references(:project)
                                 .where(project: projects)
    end

    def find_board
      @board_grid = Boards::Grid.find_by!(id: params[:id], project: @project)
    end

    def find_board_for_deletion
      @board_grid = Boards::Grid.find_by!(id: params[:id], project: @project)
    end

    def authorize_work_package_permission
      unless user_allowed_to_view_work_packages?
        deny_access
      end
    end

    def user_allowed_to_view_work_packages?
      if @project
        current_user.allowed_in_project?(:view_work_packages, @project)
      else
        current_user.allowed_in_any_project?(:view_work_packages)
      end
    end

    def build_board_grid
      @board_grid = Boards::Grid.new
    end

    def service_call
      service_class.new(user: User.current)
                   .call(
                     project: @project,
                     name: board_grid_params[:name],
                     attribute: board_grid_params[:attribute]
                   )
    end

    def service_class
      {
        "basic" => Boards::BasicBoardCreateService,
        "status" => Boards::StatusBoardCreateService,
        "assignee" => Boards::AssigneeBoardCreateService,
        "version" => Boards::VersionBoardCreateService,
        "subproject" => Boards::SubprojectBoardCreateService,
        "subtasks" => Boards::SubtasksBoardCreateService
      }.fetch(board_grid_params[:attribute])
    end

    def board_grid_params
      params.expect(boards_grid: %i[name attribute])
    end
  end
end
