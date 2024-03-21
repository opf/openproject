#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkflowsController < ApplicationController
  layout 'admin'

  before_action :require_admin

  before_action :find_roles, except: :update
  before_action :find_types, except: :update

  before_action :find_role, only: :update
  before_action :find_type, only: :update

  before_action :find_optional_role, only: :edit
  before_action :find_optional_type, only: :edit

  def show
    @workflow_counts = Workflow.count_by_type_and_role
  end

  def edit
    @used_statuses_only = params[:used_statuses_only] != '0'

    statuses_for_form

    if @type && @role && @statuses.any?
      workflows_for_form
    end
  end

  def update
    call = Workflows::BulkUpdateService
           .new(role: @role, type: @type)
           .call(params['status'])

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: 'edit', role_id: @role, type_id: @type
    end
  end

  def copy
    @source_type = if params[:source_type_id].blank? || params[:source_type_id] == 'any'
                     nil
                   else
                     ::Type.find(params[:source_type_id])
                   end
    @source_role = if params[:source_role_id].blank? || params[:source_role_id] == 'any'
                     nil
                   else
                     eligible_roles.find(params[:source_role_id])
                   end

    @target_types = params[:target_type_ids].blank? ? nil : ::Type.where(id: params[:target_type_ids])
    @target_roles = params[:target_role_ids].blank? ? nil : eligible_roles.where(id: params[:target_role_ids])

    if request.post?
      if params[:source_type_id].blank? || params[:source_role_id].blank? || (@source_type.nil? && @source_role.nil?)
        flash.now[:error] = I18n.t(:error_workflow_copy_source)
      elsif @target_types.nil? || @target_roles.nil?
        flash.now[:error] = I18n.t(:error_workflow_copy_target)
      else
        Workflow.copy(@source_type, @source_role, @target_types, @target_roles)
        flash[:notice] = I18n.t(:notice_successful_update)
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

  def statuses_for_form
    @statuses = if @type && @used_statuses_only && @type.statuses.any?
                  @type.statuses
                else
                  Status.all
                end
  end

  def workflows_for_form
    workflows = Workflow.where(role_id: @role.id, type_id: @type.id)
    @workflows = {}
    @workflows['always'] = workflows.select { |w| !w.author && !w.assignee }
    @workflows['author'] = workflows.select(&:author)
    @workflows['assignee'] = workflows.select(&:assignee)
  end

  def find_roles
    @roles = eligible_roles.order(:builtin, :position)
  end

  def find_types
    @types = ::Type.order(:position)
  end

  def find_role
    @role = eligible_roles.find(params[:role_id])
  end

  def find_type
    @type = ::Type.find(params[:type_id])
  end

  def find_optional_role
    @role = eligible_roles.find_by(id: params[:role_id])
  end

  def find_optional_type
    @type = ::Type.find_by(id: params[:type_id])
  end

  def eligible_roles
    roles = Role.where(type: ProjectRole.name)

    if EnterpriseToken.allows_to?(:work_package_sharing)
      roles.or(Role.where(builtin: Role::BUILTIN_WORK_PACKAGE_EDITOR))
    else
      roles
    end
  end
end
