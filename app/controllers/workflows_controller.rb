#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkflowsController < ApplicationController
  layout 'admin'

  before_filter :require_admin
  before_filter :find_roles
  before_filter :find_trackers

  def index
    @workflow_counts = Workflow.count_by_tracker_and_role
  end

  def edit
    @role = Role.find_by_id(params[:role_id])
    @tracker = Tracker.find_by_id(params[:tracker_id])

    if request.post?
      Workflow.destroy_all( ["role_id=? and tracker_id=?", @role.id, @tracker.id])
      (params[:issue_status] || []).each { |status_id, transitions|
        transitions.each { |new_status_id, options|
          author = options.is_a?(Array) && options.include?('author') && !options.include?('always')
          assignee = options.is_a?(Array) && options.include?('assignee') && !options.include?('always')
          @role.workflows.build(:tracker_id => @tracker.id, :old_status_id => status_id, :new_status_id => new_status_id, :author => author, :assignee => assignee)
        }
      }
      if @role.save
        flash[:notice] = l(:notice_successful_update)
        redirect_to :action => 'edit', :role_id => @role, :tracker_id => @tracker
        return
      end
    end

    @used_statuses_only = (params[:used_statuses_only] == '0' ? false : true)
    if @tracker && @used_statuses_only && @tracker.issue_statuses.any?
      @statuses = @tracker.issue_statuses
    end
    @statuses ||= IssueStatus.find(:all, :order => 'position')

    if @tracker && @role && @statuses.any?
      workflows = Workflow.all(:conditions => {:role_id => @role.id, :tracker_id => @tracker.id})
      @workflows = {}
      @workflows['always'] = workflows.select {|w| !w.author && !w.assignee}
      @workflows['author'] = workflows.select {|w| w.author}
      @workflows['assignee'] = workflows.select {|w| w.assignee}
    end
  end

  def copy

    if params[:source_tracker_id].blank? || params[:source_tracker_id] == 'any'
      @source_tracker = nil
    else
      @source_tracker = Tracker.find_by_id(params[:source_tracker_id].to_i)
    end
    if params[:source_role_id].blank? || params[:source_role_id] == 'any'
      @source_role = nil
    else
      @source_role = Role.find_by_id(params[:source_role_id].to_i)
    end

    @target_trackers = params[:target_tracker_ids].blank? ? nil : Tracker.find_all_by_id(params[:target_tracker_ids])
    @target_roles = params[:target_role_ids].blank? ? nil : Role.find_all_by_id(params[:target_role_ids])

    if request.post?
      if params[:source_tracker_id].blank? || params[:source_role_id].blank? || (@source_tracker.nil? && @source_role.nil?)
        flash.now[:error] = l(:error_workflow_copy_source)
      elsif @target_trackers.nil? || @target_roles.nil?
        flash.now[:error] = l(:error_workflow_copy_target)
      else
        Workflow.copy(@source_tracker, @source_role, @target_trackers, @target_roles)
        flash[:notice] = l(:notice_successful_update)
        redirect_to :action => 'copy', :source_tracker_id => @source_tracker, :source_role_id => @source_role
      end
    end
  end

  private

  def find_roles
    @roles = Role.find(:all, :order => 'builtin, position')
  end

  def find_trackers
    @trackers = Tracker.find(:all, :order => 'position')
  end
end
