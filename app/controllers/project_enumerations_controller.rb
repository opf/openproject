class ProjectEnumerationsController < ApplicationController
  before_filter :find_project
  before_filter :authorize
  
  def save
    if request.post? && params[:enumerations]
      Project.transaction do
        params[:enumerations].each do |id, activity|
          @project.update_or_create_time_entry_activity(id, activity)
        end
      end
      flash[:notice] = l(:notice_successful_update)
    end
    
    redirect_to :controller => 'projects', :action => 'settings', :tab => 'activities', :id => @project
  end

end
