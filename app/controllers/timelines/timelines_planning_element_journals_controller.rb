class Timelines::TimelinesPlanningElementJournalsController < ApplicationController
  unloadable
  helper :timelines

  include Timelines::ExtendedHTTP

  before_filter :find_project_by_project_id
  before_filter :find_planning_element_by_planning_element_id
  before_filter :authorize

  accept_key_auth :index, :create

  def index
    @journals = @planning_element.journals
    respond_to do |format|
      format.html { render_404 }
      format.api
    end
  end

  def create
    raise NotImplementedError
  end

  protected

  def find_planning_element_by_planning_element_id
    raise ActiveRecord::RecordNotFound if @project.blank?
    @planning_element = @project.timelines_planning_elements.find(params[:planning_element_id])
  end
end
