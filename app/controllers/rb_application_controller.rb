# Base class of all controllers in Redmine Backlogs
class RbApplicationController < ApplicationController
  unloadable

  before_filter :load_project, :authorize, :check_if_plugin_is_configured

  private
  
  # Loads the project to be used by the authorize filter to
  # determine if User.current has permission to invoke the method in question.
  def load_project
    @project = if params[:sprint_id]
                 load_sprint
                 @sprint.project
               elsif params[:project_id]
                 Project.find(params[:project_id])
               else
                 raise "Cannot determine project (#{params.inspect})"
               end
  end

  def check_if_plugin_is_configured
    settings = Setting.plugin_redmine_backlogs
    if settings[:story_trackers].blank? || settings[:task_tracker].blank?
      respond_to do |format|
        format.html { render :file => "rb_common/not_configured" }
      end
    end
  end

  def load_sprint
    @sprint = Sprint.find(params[:sprint_id])
  end  
end
