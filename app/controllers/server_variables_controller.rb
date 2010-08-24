class ServerVariablesController < ApplicationController
  unloadable
  before_filter :find_project, :authorize

  def index
    @sprint = params[:sprint_id] ? Sprint.find(params[:sprint_id]) : nil
    render :action => 'index.js', :content_type => 'text/javascript', :layout => false
  end
  
  private
  
  def find_project
    @project = (params[:project_id] ? Project.find(params[:project_id]) : @sprint.project)
  end
end