#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkflowsController < ApplicationController
  layout 'admin'

  before_action :require_admin
  before_action :find_roles
  before_action :find_types

  def index
    @workflow_counts = Workflow.count_by_type_and_role
  end

  def edit
    @role = Role.find_by(id: params[:role_id])
    @type = ::Type.find_by(id: params[:type_id])

    if request.post?
      Workflow.where(role_id: @role.id, type_id: @type.id).delete_all
      (params[:status] || []).each do |status_id, transitions|
        transitions.each { |new_status_id, options|
          author = options.is_a?(Array) && options.include?('author') && !options.include?('always')
          assignee = options.is_a?(Array) && options.include?('assignee') && !options.include?('always')
          @role.workflows.build(type_id: @type.id, old_status_id: status_id, new_status_id: new_status_id, author: author, assignee: assignee)
        }
      end
      if @role.save
        flash[:notice] = l(:notice_successful_update)
        redirect_to action: 'edit', role_id: @role, type_id: @type
        return
      end
    end

    @used_statuses_only = params[:used_statuses_only] != '0'
    if @type && @used_statuses_only && @type.statuses.any?
      @statuses = @type.statuses
    end
    @statuses ||= Status.all

    if @type && @role && @statuses.any?
      workflows = Workflow.where(role_id: @role.id, type_id: @type.id)
      @workflows = {}
      @workflows['always'] = workflows.select { |w| !w.author && !w.assignee }
      @workflows['author'] = workflows.select(&:author)
      @workflows['assignee'] = workflows.select(&:assignee)
    end
  end

  def copy
    if params[:source_type_id].blank? || params[:source_type_id] == 'any'
      @source_type = nil
    else
      @source_type = ::Type.find_by(id: params[:source_type_id].to_i)
    end
    if params[:source_role_id].blank? || params[:source_role_id] == 'any'
      @source_role = nil
    else
      @source_role = Role.find_by(id: params[:source_role_id].to_i)
    end

    @target_types = params[:target_type_ids].blank? ? nil : ::Type.where(id: params[:target_type_ids])
    @target_roles = params[:target_role_ids].blank? ? nil : Role.where(id: params[:target_role_ids])

    if request.post?
      if params[:source_type_id].blank? || params[:source_role_id].blank? || (@source_type.nil? && @source_role.nil?)
        flash.now[:error] = l(:error_workflow_copy_source)
      elsif @target_types.nil? || @target_roles.nil?
        flash.now[:error] = l(:error_workflow_copy_target)
      else
        Workflow.copy(@source_type, @source_role, @target_types, @target_roles)
        flash[:notice] = l(:notice_successful_update)
        redirect_to action: 'copy', source_type_id: @source_type, source_role_id: @source_role
      end
    end
  end

  def default_breadcrumb
    if action_name == 'edit'
      t('label_workflow')
    else
      ActionController::Base.helpers.link_to(t('label_workflow'), url_for(controller: '/workflows', action: 'edit'))
    end
  end

  def show_local_breadcrumb
    true
  end

  private

  def find_roles
    @roles = Role.order('builtin, position')
  end

  def find_types
    @types = ::Type.order('position')
  end
end
