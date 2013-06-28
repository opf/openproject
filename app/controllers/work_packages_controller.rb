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

class WorkPackagesController < ApplicationController
  unloadable

  helper :timelines, :planning_elements

  include ExtendedHTTP

  menu_item :planning_elements
  model_object PlanningElement

  before_filter :disable_api
  before_filter :find_model_object_and_project,
                :authorize,
                :assign_planning_elements
  before_filter :apply_at_timestamp, :only => [:show]

  # Attention: find_all_projects_by_project_id needs to mimic all of the above
  #            before filters !!!
  before_filter :find_all_projects_by_project_id, :only => :index

  helper :timelines
  helper :timelines_journals

  def show
    respond_to do |format|
      format.html
      format.js { render :partial => 'show'}
    end
  end

  def work_package
    @work_package ||= begin

      wp = PlanningElement.includes(:project)
                          .find_by_id(params[:id])

      wp && wp.visible?(current_user) ?
        wp :
        nil
    end
  end

  def project
    work_package.project
  end

  [:journals, :changesets, :relations, :ancestors, :descendants].each do |method|
    define_method method do
      []
    end
  end

  def edit_allowed?
    false
    #@edit_allowed ||= current_user.allowed_to?(:edit_work_packages, project)
  end

  protected

  def assign_planning_elements
    @planning_elements = @project.planning_elements.without_deleted
  end

  def apply_at_timestamp
    return if params[:at].blank?

    time = Time.at(Integer(params[:at]))
    # intentionally rebuilding scope chain to avoid without_deleted scope
    @planning_elements = @project.planning_elements.at_time(time)

  rescue ArgumentError
    render_errors(:at => 'unknown format')
  end
end
