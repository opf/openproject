class ActivitiesController < ApplicationController
  menu_item :activity
  before_filter :find_optional_project
  accept_key_auth :index

  def index
    @days = Setting.activity_days_default.to_i
    
    if params[:from]
      begin; @date_to = params[:from].to_date + 1; rescue; end
    end

    @date_to ||= Date.today + 1
    @date_from = @date_to - @days
    @with_subprojects = params[:with_subprojects].nil? ? Setting.display_subprojects_issues? : (params[:with_subprojects] == '1')
    @author = (params[:user_id].blank? ? nil : User.active.find(params[:user_id]))
    
    @activity = Redmine::Activity::Fetcher.new(User.current, :project => @project, 
                                                             :with_subprojects => @with_subprojects,
                                                             :author => @author)
    @activity.scope_select {|t| !params["show_#{t}"].nil?}
    @activity.scope = (@author.nil? ? :default : :all) if @activity.scope.empty?

    events = @activity.events(@date_from, @date_to)
    
    if events.empty? || stale?(:etag => [@activity.scope, @date_to, @date_from, @with_subprojects, @author, events.first, User.current, current_language])
      respond_to do |format|
        format.html { 
          @events_by_day = events.group_by(&:event_date)
          render :layout => false if request.xhr?
        }
        format.atom {
          title = l(:label_activity)
          if @author
            title = @author.name
          elsif @activity.scope.size == 1
            title = l("label_#{@activity.scope.first.singularize}_plural")
          end
          render_feed(events, :title => "#{@project || Setting.app_title}: #{title}")
        }
      end
    end
    
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  # TODO: refactor, duplicated in projects_controller
  def find_optional_project
    return true unless params[:id]
    @project = Project.find(params[:id])
    authorize
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
