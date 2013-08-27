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

  include Redmine::Export::PDF

  current_menu_item do |controller|
    begin
      wp = controller.work_package

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

  before_filter :disable_api
  before_filter :not_found_unless_work_package,
                :project,
                :authorize

  def show
    respond_to do |format|
      format.html do
        render :show, :locals => { :work_package => work_package,
                                   :project => project,
                                   :priorities => priorities,
                                   :user => current_user,
                                   :ancestors => ancestors,
                                   :descendants => descendants,
                                   :changesets => changesets,
                                   :relations => relations,
                                   :journals => journals }
      end

      format.js do
        render :show, :partial => 'show', :locals => { :work_package => work_package,
                                                       :project => project,
                                                       :priorities => priorities,
                                                       :user => current_user,
                                                       :ancestors => ancestors,
                                                       :descendants => descendants,
                                                       :changesets => changesets,
                                                       :relations => relations,
                                                       :journals => journals }
      end

      format.pdf do
        pdf = issue_to_pdf(work_package)

        send_data(pdf,
                  :type => 'application/pdf',
                  :filename => "#{project.identifier}-#{work_package.id}.pdf")
      end
    end
  end

  def new
    respond_to do |format|
      format.html { render :locals => { :work_package => work_package,
                                        :project => project,
                                        :priorities => priorities,
                                        :user => current_user } }
    end
  end

  def new_type
    safe_params = permitted_params.update_work_package(:project => project)
    work_package.update_by(current_user, safe_params)

    respond_to do |format|
      format.js { render :locals => { :work_package => work_package,
                                      :project => project,
                                      :priorities => priorities,
                                      :user => current_user } }
    end
  end

  def preview
    safe_params = permitted_params.update_work_package(:project => project)
    work_package.update_by(current_user, safe_params)

    respond_to do |format|
      format.any(:html, :js) { render 'preview', :locals => { :work_package => work_package },
                                                 :layout => false }
    end
  end

  def create
    call_hook(:controller_work_package_new_before_save, { :params => params, :work_package => work_package })

    WorkPackageObserver.instance.send_notification = send_notifications?

    if work_package.save
      flash[:notice] = I18n.t(:notice_successful_create)

      Attachment.attach_files(work_package, params[:attachments])
      render_attachment_warning_if_needed(work_package)

      call_hook(:controller_work_pacakge_new_after_save, { :params => params, :work_package => work_package })

      redirect_to(work_package_path(work_package))
    else
      respond_to do |format|
        format.html { render :action => 'new' }
      end
    end
  end

  def edit
    locals =   { :work_package => work_package,
                 :allowed_statuses => allowed_statuses,
                 :project => project,
                 :priorities => priorities,
                 :time_entry => time_entry,
                 :user => current_user }

    respond_to do |format|
      format.html do
        render :edit, :locals => locals
      end
      format.js do
        render :partial => "edit", :locals => locals
      end
    end
  end

  def update
    configure_update_notification(send_notifications?)

    safe_params = permitted_params.update_work_package(:project => project)
    updated = work_package.update_by!(current_user, safe_params)

    render_attachment_warning_if_needed(work_package)

    if updated

      flash[:notice] = l(:notice_successful_update)

      show
    else
      edit
    end
  end


  def work_package
    if params[:id]
      existing_work_package
    elsif params[:project_id]
      new_work_package
    end
  end

  def existing_work_package
    @existing_work_package ||= begin

      wp = WorkPackage.includes(:project)
                      .find_by_id(params[:id])

      wp && wp.visible?(current_user) ?
        wp :
        nil
    end
  end

  def new_work_package
    @new_work_package ||= begin
      project = Project.find_visible(current_user, params[:project_id])
      return nil unless project

      permitted = if params[:work_package]
                    permitted_params.new_work_package(:project => project)
                  else
                    params[:work_package] ||= {}
                    {}
                  end

      permitted[:author] = current_user

      sti_type = params[:sti_type] || params[:work_package][:sti_type] || 'Issue'

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
    @project ||= work_package.project
  end

  def journals
    @journals ||= work_package.journals.changing
                                       .includes(:user)
                                       .order("#{Journal.table_name}.created_at ASC")
  end

  def ancestors
    @ancestors ||= work_package.ancestors.visible.includes(:type,
                                                           :assigned_to,
                                                           :status,
                                                           :priority,
                                                           :fixed_version,
                                                           :project)
  end

  def descendants
    @descendants ||= work_package.descendants.visible.includes(:type,
                                                               :assigned_to,
                                                               :status,
                                                               :priority,
                                                               :fixed_version,
                                                               :project)

  end

  def changesets
    @changesets ||= begin
      changes = work_package.changesets.visible
                                       .includes({ :repository => {:project => :enabled_modules} }, :user)
                                       .all

      changes.reverse! if current_user.wants_comments_in_reverse_order?

      changes
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

  def not_found_unless_work_package
    render_404 unless work_package
  end

  def configure_update_notification(state = true)
    JournalObserver.instance.send_notification = state
  end

  def send_notifications?
    params[:send_notification] == '0' ? false : true
  end
end
