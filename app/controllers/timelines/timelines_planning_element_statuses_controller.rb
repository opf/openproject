class Timelines::TimelinesPlanningElementStatusesController < ApplicationController
  unloadable
  helper :timelines

  accept_key_auth :index, :show

  def index
    @planning_element_statuses = Timelines::PlanningElementStatus.active
    respond_to do |format|
      format.html { render_404 }
      format.api
    end
  end

  def show
    @planning_element_status = Timelines::PlanningElementStatus.active.find(params[:id])
    respond_to do |format|
      format.html { render_404 }
      format.api
    end
  end
end
