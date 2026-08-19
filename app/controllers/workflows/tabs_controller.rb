# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

class Workflows::TabsController < ApplicationController
  include OpTurbo::ComponentStream

  layout false

  before_action :require_admin

  before_action :set_type
  before_action :set_tab
  before_action :set_eligible_roles
  before_action :set_roles

  def edit
    unless turbo_frame_request?
      redirect_to edit_workflow_path(@type, role_ids: params[:role_ids], tab: @tab)
      return
    end

    statuses_for_form

    if @type && @roles.any? && @statuses.any?
      workflows_for_form
    end
  end

  def update # rubocop:disable Metrics/AbcSize
    success = false
    Workflow.transaction do
      success = true
      base_params = permitted_status_params
      indeterminate = permitted_indeterminate_params
      @roles.each do |role|
        role_params = indeterminate.empty? ? base_params : role_specific_params(base_params, indeterminate, role)
        result = Workflows::BulkUpdateService.new(role:, type: @type, tab: @tab)
                                             .call(role_params)
        success = false unless result.success?
      end
      raise ActiveRecord::Rollback unless success
    end

    if success
      render_flash_message_via_turbo_stream(
        message: I18n.t(:notice_successful_update),
        scheme: :success
      )
      statuses = statuses_for_form
      if statuses.empty?
        # Need to replace with the blankslate.
        update_via_turbo_stream(
          component: Workflows::StatusMatrixFormComponent.new(
            tab: @tab,
            roles: @roles,
            type: @type,
            available_roles: @eligible_roles,
            statuses:,
            has_status_changes: @has_status_changes
          )
        )
      end
    else
      render_flash_message_via_turbo_stream(
        message: I18n.t(:notice_unsuccessful_update),
        scheme: :danger
      )
      @turbo_status = :unprocessable_entity
    end

    respond_with_turbo_streams
  end

  def status_dialog
    all_statuses = Status.order(:position)
    current_statuses = if params[:status_ids].present?
                         Status.where(id: params[:status_ids].map(&:to_i)).order(:position)
                       elsif @type && @roles.any?
                         statuses_for_roles_and_type
                       else
                         Status.none
                       end

    respond_with_dialog Workflows::StatusDialogComponent.new(
      all_statuses:,
      current_statuses:,
      roles: @roles,
      type: @type,
      tab: @tab
    )
  end

  def confirm_statuses # rubocop:disable Metrics/AbcSize
    current_status_ids = Array(params[:status_ids]).flatten.map(&:to_i)
    original_ids = Array(params[:original_status_ids]).flatten.map(&:to_i)
    removed_count = (original_ids - current_status_ids).size

    if removed_count > 0
      respond_with_dialog Workflows::StatusRemovalDangerDialogComponent.new(
        roles: @roles,
        type: @type,
        tab: @tab,
        status_ids: current_status_ids,
        removed_count: removed_count
      )
    else
      statuses = statuses_for_form.tap { workflows_for_form }
      update_via_turbo_stream(
        component: Workflows::StatusMatrixFormComponent.new(
          tab: @tab,
          roles: @roles,
          type: @type,
          available_roles: @eligible_roles,
          statuses:,
          has_status_changes: @has_status_changes
        )
      )
      respond_with_turbo_streams
    end
  end

  private

  def set_type
    @type = ::Type.find(params[:workflow_type_id])
  end

  def set_tab
    @tab = params[:tab]
  end

  def set_eligible_roles
    @eligible_roles = Workflow.eligible_roles.order(:builtin, :position)
  end

  def set_roles
    @roles = @eligible_roles.where(id: params[:role_ids])
    @roles = [@eligible_roles.first] if @roles.empty?
  end

  def statuses_for_form
    @added_status_ids = []
    @has_status_changes = false
    @statuses = if @type && params[:status_ids].present?
                  statuses_from_params
                elsif @type && @roles.any?
                  statuses_for_roles_and_type
                elsif @type
                  @type.statuses
                else
                  Status.all
                end
  end

  def statuses_from_params
    status_ids = params[:status_ids].map(&:to_i)
    saved_ids = statuses_for_roles_and_type.pluck(:id)
    @added_status_ids = status_ids - saved_ids
    @has_status_changes = @added_status_ids.any? || (saved_ids - status_ids).any?
    Status.where(id: status_ids).order(:position)
  end

  def statuses_for_roles_and_type
    status_ids = @roles.map { |role| @type.statuses(role:, tab: @tab).pluck(:id) }.flatten.uniq
    Status.where(id: status_ids)
  end

  def workflows_for_form
    workflows = Workflow.where(role_id: @roles.map(&:id), type_id: @type.id)
    @workflows = {}
    @workflows["always"] = workflows.select { |w| !w.author && !w.assignee }
    @workflows["author"] = workflows.select(&:author)
    @workflows["assignee"] = workflows.select(&:assignee)
  end

  def permitted_status_params
    status_params("status")
  end

  def permitted_indeterminate_params
    status_params("indeterminate_status")
  end

  def status_params(key)
    return {} if params[key].blank?

    params[key]
      .to_unsafe_h
      .select { |k, value| /\A\d+\z/.match?(k) && value.keys.all? { /\A\d+\z/.match?(it) } }
  end

  def role_specific_params(base_params, indeterminate, role)
    params = base_params.deep_dup
    indeterminate.each do |old_id, new_ids|
      new_ids.each_key do |new_id|
        # Restore from DB so that it isn't overwritten by indeterminate state (unchecked)
        had_transition = Workflow.exists?(
          role_id: role.id,
          type_id: @type.id,
          old_status_id: old_id.to_i,
          new_status_id: new_id.to_i,
          author: @tab == "author",
          assignee: @tab == "assignee"
        )
        if had_transition
          params[old_id] ||= {}
          params[old_id][new_id] = "1"
        end
      end
    end
    params
  end
end
