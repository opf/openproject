module ::Boards
  class BoardsController < BaseController
    before_action :find_optional_project
    before_action :build_board_grid, only: %i[new]

    with_options only: %i[index show] do
      # The boards permission alone does not suffice
      # to view work packages
      before_action :authorize
      before_action :authorize_work_package_permission
    end

    before_action :authorize_global, only: %i[overview new create]
    before_action :ensure_board_type_not_restricted, only: %i[create]

    menu_item :board_view

    def index
      @board_grids = Boards::Grid.includes(:project).where(project: @project)
    end

    def overview
      projects = Project.allowed_to(User.current, :show_board_views)
      @board_grids = Boards::Grid.includes(:project).where(project: projects)
      render layout: 'global'
    end

    current_menu_item :index do
      :board_view
    end

    current_menu_item :overview do
      :boards
    end

    def show
      render layout: 'angular/angular'
    end

    def new; end

    def create
      service_result = service_call

      @board_grid = service_result.result

      if service_result.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to project_work_package_board_path(@project, @board_grid)
      else
        @errors = service_result.errors
        render action: :new
      end
    end

    private

    def authorize_work_package_permission
      unless current_user.allowed_to?(:view_work_packages, @project, global: @project.nil?)
        deny_access
      end
    end

    def build_board_grid
      @board_grid = Boards::Grid.new
    end

    def ensure_board_type_not_restricted
      render_403 if restricted_board_type?
    end

    def restricted_board_type?
      !EnterpriseToken.allows_to?(:board_view) && board_grid_params[:attribute] != 'basic'
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
        'basic' => Boards::BasicBoardCreateService,
        'status' => Boards::StatusBoardCreateService,
        'assignee' => Boards::AssigneeBoardCreateService,
        'version' => Boards::VersionBoardCreateService,
        'subproject' => Boards::SubprojectBoardCreateService,
        'subtasks' => Boards::SubtasksBoardCreateService
      }.fetch(board_grid_params[:attribute])
    end

    def board_grid_params
      params.require(:boards_grid).permit(%i[name attribute])
    end
  end
end
