# Base class of all controllers in Backlogs
class RbApplicationController < ApplicationController
  unloadable

  helper :rb_common

  before_filter :load_sprint_and_project, :authorize, :check_if_plugin_is_configured

  private

  # Loads the project to be used by the authorize filter to determine if
  # User.current has permission to invoke the method in question.
  def load_sprint_and_project
    if params[:sprint_id]
      @sprint = Sprint.find(params[:sprint_id])
      @project = @sprint.project
    end
    # This overrides sprint's project if we set another project, say a subproject
    @project = Project.find(params[:project_id]) if params[:project_id]
  end

  def check_if_plugin_is_configured
    settings = Setting.plugin_openproject_backlogs
    if settings["story_types"].blank? || settings["task_type"].blank?
      respond_to do |format|
        format.html { render :file => "shared/not_configured" }
      end
    end
  end
end
