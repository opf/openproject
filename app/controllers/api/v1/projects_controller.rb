module Api
  module V1

    class ProjectsController < ProjectsController

      include ::Api::V1::ApiController

      def index
        @offset, @limit = api_offset_and_limit
        @project_count = Project.visible.count
        @projects = Project.visible.all(:offset => @offset, :limit => @limit, :order => 'lft')

        respond_to do |format|
          format.api
        end
      end

      def show
        @users_by_role = @project.users_by_role
        @subprojects = @project.children.visible.all
        @news = @project.news.find(:all, :limit => 5, :include => [ :author, :project ], :order => "#{News.table_name}.created_on DESC")
        @trackers = @project.rolled_up_trackers

        cond = @project.project_condition(Setting.display_subprojects_issues?)

        @open_issues_by_tracker = Issue.visible.count(:group => :tracker,
                                                :include => [:project, :status, :tracker],
                                                :conditions => ["(#{cond}) AND #{IssueStatus.table_name}.is_closed=?", false])
        @total_issues_by_tracker = Issue.visible.count(:group => :tracker,
                                                :include => [:project, :status, :tracker],
                                                :conditions => cond)

        if User.current.allowed_to?(:view_time_entries, @project)
          @total_hours = TimeEntry.visible.sum(:hours, :include => :project, :conditions => cond).to_f
        end

        respond_to do |format|
          format.api
        end
      end

      def level_list
        respond_to do |format|
          format.html { render_404 }
          format.api {
            @elements = Project.project_level_list(Project.visible)
          }
        end
      end

      def update
        @project.safe_attributes = params[:project]
        if validate_parent_id && @project.save
          @project.set_allowed_parent!(params[:project]['parent_id']) if params[:project].has_key?('parent_id')
          respond_to do |format|
            format.api { head :ok }
          end
        else
          respond_to do |format|
            format.api { render_validation_errors(@project) }
          end
        end
      end

      def destroy
        @project_to_destroy = @project
        @project_to_destroy.destroy

        respond_to do |format|
          format.api  { head :ok }
        end
      end

      def create
        @issue_custom_fields = IssueCustomField.find(:all, :order => "#{CustomField.table_name}.position")
        @trackers = Tracker.all
        @project = Project.new
        @project.safe_attributes = params[:project]

        if validate_parent_id && @project.save
          @project.set_allowed_parent!(params[:project]['parent_id']) if params[:project].has_key?('parent_id')
          add_current_user_to_project_if_not_admin(@project)
          respond_to do |format|
            format.api  { render :action => 'show', :status => :created, :location => url_for(:controller => '/projects', :action => 'show', :id => @project.id) }
          end
        else
          respond_to do |format|
            format.api  { render_validation_errors(@project) }
          end
        end
      end

    end
  end
end
