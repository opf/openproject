class ChartsController < ApplicationController
  unloadable
  before_filter :find_project, :authorize
  
  def show
    @data = BacklogChartData.fetch :backlog_id => params[:backlog_id]
    
    if @data.nil?
      render :text => "<span>No chart data.</span>"
    elsif params[:src]=="gchart"
      render :partial => "gchart"
    else
      render :text => "You must supply src", :status => 400
    end
  end
  
  private
  
  def find_project
    @project = Backlog.find(params[:backlog_id]).version.project
  end
  
end