# Base class of all controllers in Redmine Backlogs
class RbApplicationController < ApplicationController
  unloadable

  helper :rb_common

  before_filter :load_project, :authorize, :check_if_plugin_is_configured

  private

  # Loads the project to be used by the authorize filter to
  # determine if User.current has permission to invoke the method in question.
  def load_project
    if params[:sprint_id]
      load_sprint_and_project
    else
      @project = Project.find(params[:project_id]) if params[:project_id]
    end
  end

  def check_if_plugin_is_configured
    settings = Setting.plugin_openproject_backlogs
    if settings["story_trackers"].blank? || settings["task_tracker"].blank?
      respond_to do |format|
        format.html { render :file => "shared/not_configured" }
      end
    end
  end

  def load_sprint_and_project(id = params[:sprint_id].to_i)
    @sprint = Sprint.find(id)
    @project = @sprint.project
  end
end
