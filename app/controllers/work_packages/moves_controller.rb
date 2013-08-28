#-- encoding: UTF-8
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

class WorkPackages::MovesController < ApplicationController
  default_search_scope :work_packages
  before_filter :find_work_packages, :check_project_uniqueness
  before_filter :authorize

  def new
    prepare_for_work_package_move
    render :layout => false if request.xhr?
  end

  def create
    prepare_for_work_package_move

    new_type = params[:new_type_id].blank? ? nil : @target_project.types.find_by_id(params[:new_type_id])
    unsaved_work_package_ids = []
    moved_work_packages = []
    @work_packages.each do |work_package|
      work_package.reload

      JournalManager.add_journal work_package, User.current, @notes || ""

      call_hook(:controller_work_packages_move_before_save, { :params => params, :work_package => work_package, :target_project => @target_project, :copy => !!@copy })
      if r = work_package.move_to_project(@target_project, new_type, {:copy => @copy, :attributes => extract_changed_attributes_for_move(params)})
        moved_work_packages << r
      else
        unsaved_work_package_ids << work_package.id
      end
    end
    set_flash_from_bulk_work_package_save(@work_packages, unsaved_work_package_ids)

    if params[:follow]
      if @work_packages.size == 1 && moved_work_packages.size == 1
        redirect_to work_package_path(moved_work_packages.first)
      else
        redirect_to project_issues_path(@target_project || @project)
      end
    else
      redirect_to project_issues_path(@project)
    end
    return
  end

  def set_flash_from_bulk_work_package_save(work_packages, unsaved_work_package_ids)
    if unsaved_work_package_ids.empty? and not work_packages.empty?
      flash[:notice] = (@copy) ? l(:notice_successful_create) : l(:notice_successful_update)
    else
      flash[:error] = l(:notice_failed_to_save_work_packages,
                        :count => unsaved_work_package_ids.size,
                        :total => work_packages.size,
                        :ids => '#' + unsaved_work_package_ids.join(', #'))
    end
  end

  def default_breadcrumb
    l(:label_move_work_package)
  end

  private

  # Filter for bulk work package operations
  def find_work_packages
    @work_packages = WorkPackage.includes(:project)
                                .find_all_by_id(params[:work_package_id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @work_packages.empty?
    @projects = @work_packages.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def prepare_for_work_package_move
    @work_packages.sort!
    @copy = params.has_key? :copy
    @allowed_projects = WorkPackage.allowed_target_projects_on_move
    @target_project = @allowed_projects.detect {|p| p.id.to_s == params[:new_project_id].to_s} if params[:new_project_id]
    @target_project ||= @project
    @types = @target_project.types
    @available_statuses = Workflow.available_statuses(@project)
    @notes = params[:notes]
    @notes ||= ''
  end

  def extract_changed_attributes_for_move(params)
    changed_attributes = {}
    [:assigned_to_id, :responsible_id, :status_id, :start_date, :due_date, :priority_id].each do |valid_attribute|
      unless params[valid_attribute].blank?
        changed_attributes[valid_attribute] = (params[valid_attribute] == 'none' ? nil : params[valid_attribute])
      end
    end
    changed_attributes
  end

end
