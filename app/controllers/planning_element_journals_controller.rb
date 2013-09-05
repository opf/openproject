#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class PlanningElementJournalsController < ApplicationController
  unloadable
  helper :timelines

  include ExtendedHTTP

  before_filter :disable_api
  before_filter :find_project_by_project_id
  before_filter :find_planning_element_by_planning_element_id
  before_filter :authorize

  accept_key_auth :index, :create

  def index
    @journals = @planning_element.journals
    respond_to do |format|
      format.html { render_404 }
    end
  end

  def create
    raise NotImplementedError
  end

  protected

  def find_planning_element_by_planning_element_id
    raise ActiveRecord::RecordNotFound if @project.blank?
    @planning_element = @project.work_packages.find(params[:planning_element_id])
  end
end
