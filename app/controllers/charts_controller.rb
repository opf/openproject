class ChartsController < ApplicationController
  unloadable

  before_filter :find_sprint, :only => [:show]
  before_filter :find_project, :authorize

  def show
    @burndown = @sprint.burndown
    render :action => "show", :layout => false
  end

  private

  def find_project
    @project = @sprint.project
  end

  def find_sprint
    @sprint = Sprint.find(params[:sprint_id])
  end
end
