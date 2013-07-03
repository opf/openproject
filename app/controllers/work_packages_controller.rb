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
  model_object WorkPackage

  before_filter :disable_api
  before_filter :find_model_object_and_project, :only => [:show]
  before_filter :find_project_by_project_id, :only => [:new]
  before_filter :authorize,
                :assign_planning_elements
  before_filter :apply_at_timestamp, :only => [:show]


  helper :timelines
  helper :timelines_journals

  def show
    respond_to do |format|
      format.html
      format.js { render :partial => 'show'}
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def work_package
    @work_package ||= begin

      wp = WorkPackage.includes(:project)
                      .find_by_id(params[:id])

      wp && wp.visible?(current_user) ?
        wp :
        nil
    end
  end

  def new_work_package
    @new_work_package ||= begin
      wp = case params[:type]
           when PlanningElement.to_s
             PlanningElement.new :project => project
           when Issue.to_s
             Issue.new :project => project
           else
             raise ArgumentError, "type #{params[:type]} is not supported"
           end
    end
  end

  def project
    @project ||= if params[:project_id]
                   find_project_by_project_id
                 else
                   work_package.project
                 end
  end

  def journals
    @journals ||= work_package.journals.changing
                                       .includes(:user, :journaled)
                                       .order("#{Journal.table_name}.created_at ASC")
  end

  def ancestors
    @ancestors ||= begin
                     case work_package
                     when PlanningElement
                       # Right now all planning_elements of a tree are part of the same project.
                       # That means that a user can either see all planning_elements or none.
                       # Thus, after access to a planning element is established (work_package) we
                       # currently need no extra check for the ancestors/descendants
                       work_package.ancestors
                     when Issue
                       work_package.ancestors.visible.includes(:tracker,
                                                               :assigned_to,
                                                               :status,
                                                               :priority,
                                                               :fixed_version,
                                                               :project)
                     else
                       []
                     end
                   end

  end

  def descendants
    @descendants ||= begin
                       case work_package
                       when PlanningElement
                         # Right now all planning_elements of a tree are part of the same project.
                         # That means that a user can either see all planning_elements or none.
                         # Thus, after access to a planning element is established (work_package) we
                         # currently need no extra check for the ancestors/descendants
                         work_package.descendants
                       when Issue
                         work_package.descendants.visible.includes(:tracker,
                                                                   :assigned_to,
                                                                   :status,
                                                                   :priority,
                                                                   :fixed_version,
                                                                   :project)
                       else
                         []
                       end
                     end

  end


  [:changesets, :relations, :allowed_statuses, :priorities].each do |method|
    define_method method do
      []
    end
  end

  WorkPackageAttribute = Struct.new(:attribute, :html_class, :value)

  WorkPackageUserAttribute = Struct.new(:attribute, :html_class, :value)

  WorkPackageProgressAttribute = Struct.new(:attribute, :html_class, :value)

  WorkPackagePlanningElementTypeAttribute = Struct.new(:attribute, :html_class, :value)

  def work_package_attributes
    if work_package.is_a? Issue
      return [
        WorkPackageAttribute.new(:status, 'status', work_package.status.name),
        WorkPackageAttribute.new(:start_date, 'start-date', format_date(work_package.start_date)),
        WorkPackageAttribute.new(:priority, 'priority', work_package.priority),
        WorkPackageAttribute.new(:due_date, 'due-date', format_date(work_package.due_date)),
        WorkPackageUserAttribute.new(:assigned_to, 'assigned-to', work_package.assigned_to),
        WorkPackageProgressAttribute.new(:done_ratio, 'progress', work_package.done_ratio),
        WorkPackageAttribute.new(:category,
                                 'category',
                                 (work_package.category.nil?) ? '' : work_package.category.name),
        WorkPackageAttribute.new(:spent_time,
                                 'spent-time',
                                 work_package.spent_hours > 0 ? (view_context.link_to l_hours(work_package.spent_hours),
                                                                 issue_time_entries_path(work_package)) : "-"),
        WorkPackageAttribute.new(:fixed_version,
                                 'fixed-version',
                                 work_package.fixed_version ? link_to_version(work_package.fixed_version) : "-"),
        WorkPackageAttribute.new(:estimated_hours, 'estimated_hours', l_hours(work_package.estimated_hours))
      ]
    elsif work_package.is_a? PlanningElement
      format_date_options = {}
      unless work_package.leaf?
        format_date_options[:title] = l("timelines.dates_are_calculated_based_on_sub_elements")
      end

      return [
        WorkPackageUserAttribute.new(:responsible, 'responsible', work_package.responsible),
        WorkPackageAttribute.new(:start_date, 'start-date', format_date(work_package.start_date)),
        WorkPackageAttribute.new(:parent_id,
                                 'planning-element-parent-id',
                                 work_package.parent ? (view_context.link_to_planning_element(work_package.parent,
                                                                                              :include_id => false)) : ''),
        WorkPackageAttribute.new(:due_date, 'due-date', format_date(work_package.end_date)),
        WorkPackageAttribute.new(:description,
                                 'description',
                                 (view_context.textilizable work_package, :description)),
        WorkPackagePlanningElementTypeAttribute.new(:type,
                                                    'planning-element-type',
                                                    work_package.planning_element_type),
      ]
    end
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
