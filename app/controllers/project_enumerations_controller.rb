class ProjectEnumerationsController < ApplicationController
  before_filter :find_project_by_project_id
  before_filter :authorize
  
  def update
    if request.put? && params[:enumerations]
      Project.transaction do
        params[:enumerations].each do |id, activity|
          @project.update_or_create_time_entry_activity(id, activity)
        end
      end
      flash[:notice] = l(:notice_successful_update)
    end
    
    redirect_to :controller => 'projects', :action => 'settings', :tab => 'activities', :id => @project
  end

  def destroy
    @project.time_entry_activities.each do |time_entry_activity|
      time_entry_activity.destroy(time_entry_activity.parent)
    end
    flash[:notice] = l(:notice_successful_update)
    redirect_to :controller => 'projects', :action => 'settings', :tab => 'activities', :id => @project
  end

end
