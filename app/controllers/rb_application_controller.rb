# Base class of all controllers in Redmine Backlogs
class RbApplicationController < ApplicationController
  unloadable

  before_filter :load_project, :authorize, :check_if_plugin_is_configured

  private
  
  # Loads the project to be used by the authorize filter to
  # determine if User.current has permission to invoke the method in question.
  def load_project
    @project = if ['rb_sprints',
                   'rb_burndown_charts',
                   'rb_wikis'].include? params[:controller]
                 Sprint.find(params[:id]).project
               
               elsif ['rb_queries',
                      'rb_master_backlogs',
                      'rb_calendars',
                      'rb_server_variables'].include? params[:controller]
                 Project.find(params[:id])
               
               elsif params[:project_id]
                 Project.find(params[:project_id])
               end
  end

  def check_if_plugin_is_configured
    settings = Setting.plugin_redmine_backlogs
    if settings[:story_trackers].nil? || settings[:task_tracker].nil?
      respond_to do |format|
        format.html { render :file => "rb_common/not_configured" }
      end
    end
  end
  
end
