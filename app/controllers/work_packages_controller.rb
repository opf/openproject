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

  current_menu_item do |controller|
    begin
      wp = controller.new_work_package || controller.work_package

      case wp
      when PlanningElement
        :planning_elements
      when Issue
        :issues
      end
    rescue
      :issues
    end
  end

  model_object WorkPackage

  before_filter :disable_api
  before_filter :find_model_object_and_project, :only => [:show, :edit]
  before_filter :find_project_by_project_id, :only => [:new, :new_type, :create]
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

  def new_type
    respond_to do |format|
      format.js { render :locals => { :work_package => new_work_package,
                                      :project => project,
                                      :priorities => priorities } }
    end
  end

  def create
    call_hook(:controller_work_package_new_before_save, { :params => params, :work_package => new_work_package })

    WorkPackageObserver.instance.send_notification = params[:send_notification] == '0' ? false : true

    if new_work_package.save
      flash[:notice] = I18n.t(:notice_successful_create)

      Attachment.attach_files(new_work_package, params[:attachments])
      render_attachment_warning_if_needed(new_work_package)

      call_hook(:controller_work_pacakge_new_after_save, { :params => params, :work_package => new_work_package })

      redirect_to(work_package_path(new_work_package))
    else
      respond_to do |format|
        format.html { render :action => 'new' }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html do
        render :locals => { :work_package => work_package,
                            :allowed_statuses => allowed_statuses,
                            :project => project,
                            :priorities => priorities,
                            :time_entry => time_entry }
      end
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
      params[:work_package] ||= {}
      sti_type = params[:sti_type] || params[:work_package][:sti_type] || 'Issue'

      permitted = permitted_params.new_work_package(:project => project)

      permitted[:author] = current_user

      wp = case sti_type
           when PlanningElement.to_s
             project.add_planning_element(permitted)
           when Issue.to_s
             project.add_issue(permitted)
           else
             raise ArgumentError, "sti_type #{ sti_type } is not supported"
           end

       wp.copy_from(params[:copy_from], :exclude => [:project_id]) if params[:copy_from]

       wp
    end
  end

  def project
    @project ||= if params[:project_id]
                   find_project_by_project_id
                 elsif work_package
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
                       work_package.ancestors.visible.includes(:type,
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
                         work_package.descendants.visible.includes(:type,
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

  [:changesets].each do |method|
    define_method method do
      []
    end
  end

  def relations
    @relations ||= work_package.relations.includes(:issue_from => [:status,
                                                                   :priority,
                                                                   :type,
                                                                   { :project => :enabled_modules }],
                                                   :issue_to => [:status,
                                                                 :priority,
                                                                 :type,
                                                                 { :project => :enabled_modules }])
                                         .select{ |r| r.other_issue(work_package) && r.other_issue(work_package).visible? }
  end

  def priorities
    IssuePriority.all
  end

  def allowed_statuses
    work_package.new_statuses_allowed_to(current_user)
  end

  def time_entry
    work_package.add_time_entry
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
