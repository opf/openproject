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

class Issues::MovesController < ApplicationController
  default_search_scope :issues
  before_filter :find_issues, :check_project_uniqueness
  before_filter :authorize

  def new
    prepare_for_issue_move
    render :layout => false if request.xhr?
  end

  def create
    prepare_for_issue_move

    if request.post?
      new_type = params[:new_type_id].blank? ? nil : @target_project.types.find_by_id(params[:new_type_id])
      unsaved_issue_ids = []
      moved_issues = []
      @issues.each do |issue|
        issue.reload
        issue.init_journal(User.current, @notes || "")
        call_hook(:controller_issues_move_before_save, { :params => params, :issue => issue, :target_project => @target_project, :copy => !!@copy })
        if r = issue.move_to_project(@target_project, new_type, {:copy => @copy, :attributes => extract_changed_attributes_for_move(params)})
          moved_issues << r
        else
          unsaved_issue_ids << issue.id
        end
      end
      set_flash_from_bulk_issue_save(@issues, unsaved_issue_ids)

      if params[:follow]
        if @issues.size == 1 && moved_issues.size == 1
          redirect_to issue_path(moved_issues.first)
        else
          redirect_to project_issues_path(@target_project || @project)
        end
      else
        redirect_to project_issues_path(@project)
      end
      return
    end
  end

  def default_breadcrumb
    l(:label_move_work_package)
  end

  private

  def prepare_for_issue_move
    @issues.sort!
    @copy = params[:copy_options] && params[:copy_options][:copy]
    @allowed_projects = Issue.allowed_target_projects_on_move
    @target_project = @allowed_projects.detect {|p| p.id.to_s == params[:new_project_id].to_s} if params[:new_project_id]
    @target_project ||= @project
    @types = @target_project.types
    @available_statuses = Workflow.available_statuses(@project)
    @notes = params[:notes]
    @notes ||= ''
  end

  def extract_changed_attributes_for_move(params)
    changed_attributes = {}
    [:assigned_to_id, :status_id, :start_date, :due_date, :priority_id].each do |valid_attribute|
      unless params[valid_attribute].blank?
        changed_attributes[valid_attribute] = (params[valid_attribute] == 'none' ? nil : params[valid_attribute])
      end
    end
    changed_attributes
  end

end
