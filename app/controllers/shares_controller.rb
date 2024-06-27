# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# ++

class SharesController < ApplicationController
  include OpTurbo::ComponentStream
  include OpTurbo::DialogStreamHelper
  include MemberHelper

  before_action :load_entity
  before_action :load_shares, only: %i[index dialog]
  before_action :load_selected_shares, only: %i[bulk_update bulk_destroy]
  before_action :load_share, only: %i[destroy update resend_invite]
  before_action :enterprise_check, only: %i[index]

  # TODO: Permission checks need to be implemented correctly depending on entity
  before_action :authorize

  def dialog
    @sharing_manageable = sharing_manageable?
    @available_roles = available_roles
  end

  def index
    unless @query.valid?
      flash.now[:error] = query.errors.full_messages
    end

    render Shares::ModalBodyComponent.new(
      entity: @entity,
      shares: @shares,
      errors: @errors,
      sharing_manageable: sharing_manageable?,
      available_roles:
    ), layout: nil
  end

  def create # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
    overall_result = []
    @errors = ActiveModel::Errors.new(self)

    find_or_create_users(send_notification: false) do |member_params|
      user = User.find_by(id: member_params[:user_id])
      if user.present? && user.locked?
        @errors.add(:base, I18n.t("sharing.warning_locked_user", user: user.name))
      else
        service_call = create_or_update_share(member_params[:user_id], [params[:member][:role_id]])
        overall_result.push(service_call)
      end
    end

    @new_shares = overall_result.map(&:result).reverse

    if overall_result.present?
      # In case the number of newly added shares is equal to the whole number of shares,
      # we have to render the whole modal again to get rid of the blankslate
      if current_visible_member_count > 1 && @new_shares.size < current_visible_member_count
        respond_with_prepend_shares
      else
        respond_with_replace_modal
      end
    else
      respond_with_new_invite_form
    end
  end

  def update
    create_or_update_share(@share.principal.id, params[:role_ids])

    load_shares

    if @shares.empty?
      respond_with_replace_modal
    elsif @shares.include?(@share)
      respond_with_update_permission_button
    else
      respond_with_remove_share
    end
  end

  def destroy
    destroy_share(@share)

    if current_visible_member_count.zero?
      respond_with_replace_modal
    else
      respond_with_remove_share
    end
  end

  def resend_invite
    OpenProject::Notifications.send(OpenProject::Events::WORK_PACKAGE_SHARED,
                                    work_package_member: @share,
                                    send_notifications: true)

    respond_with_update_user_details
  end

  def bulk_update
    @selected_shares.each { |share| create_or_update_share(share.principal.id, params[:role_ids]) }

    respond_with_bulk_updated_permission_buttons
  end

  def bulk_destroy
    @selected_shares.each { |share| destroy_share(share) }

    if current_visible_member_count.zero?
      respond_with_replace_modal
    else
      respond_with_bulk_removed_shares
    end
  end

  private

  def enterprise_check
    return if EnterpriseToken.allows_to?(:work_package_sharing)

    render Shares::ModalUpsaleComponent.new
  end

  def destroy_share(share)
    Shares::DeleteService
      .new(user: current_user, model: share, contract_class: sharing_contract_scope::DeleteContract)
      .call
  end

  def create_or_update_share(user_id, role_ids)
    Shares::CreateOrUpdateService.new(
      user: current_user,
      create_contract_class: sharing_contract_scope::CreateContract,
      update_contract_class: sharing_contract_scope::UpdateContract
    )
                                 .call(entity: @entity, user_id:, role_ids:)
  end

  def respond_with_replace_modal
    replace_via_turbo_stream(
      component: Shares::ModalBodyComponent.new(
        entity: @entity,
        available_roles:,
        shares: @new_shares || load_shares,
        sharing_manageable: sharing_manageable?,
        errors: @errors
      )
    )

    respond_with_turbo_streams
  end

  def respond_with_prepend_shares # rubocop:disable Metrics/AbcSize
    replace_via_turbo_stream(
      component: Shares::InviteUserFormComponent.new(
        entity: @entity,
        available_roles:,
        sharing_manageable: sharing_manageable?,
        errors: @errors
      )
    )

    update_via_turbo_stream(
      component: Shares::CounterComponent.new(
        entity: @entity,
        count: current_visible_member_count,
        sharing_manageable: sharing_manageable?
      )
    )

    @new_shares.each do |share|
      prepend_via_turbo_stream(
        component: Shares::ShareRowComponent.new(
          share:,
          available_roles:,
          sharing_manageable: sharing_manageable?
        ),
        target_component: Shares::ModalBodyComponent.new(
          entity: @entity,
          available_roles:,
          sharing_manageable: sharing_manageable?,
          shares: load_shares,
          errors: @errors
        )
      )
    end

    respond_with_turbo_streams
  end

  def respond_with_new_invite_form
    replace_via_turbo_stream(
      component: Shares::InviteUserFormComponent.new(
        entity: @entity,
        available_roles:,
        sharing_manageable: sharing_manageable?,
        errors: @errors
      )
    )

    respond_with_turbo_streams
  end

  def respond_with_update_permission_button
    replace_via_turbo_stream(
      component: Shares::PermissionButtonComponent.new(
        share: @share,
        available_roles:,
        data: { "test-selector": "op-share-dialog-update-role" }
      )
    )

    respond_with_turbo_streams
  end

  def respond_with_remove_share
    remove_via_turbo_stream(
      component: Shares::ShareRowComponent.new(
        share: @share,
        available_roles:,
        sharing_manageable: sharing_manageable?
      )
    )
    update_via_turbo_stream(
      component: Shares::CounterComponent.new(
        entity: @entity,
        count: current_visible_member_count,
        sharing_manageable: sharing_manageable?
      )
    )

    respond_with_turbo_streams
  end

  def respond_with_update_user_details
    update_via_turbo_stream(
      component: Shares::UserDetailsComponent.new(
        share: @share,
        manager_mode: sharing_manageable?,
        invite_resent: true
      )
    )

    respond_with_turbo_streams
  end

  def respond_with_bulk_updated_permission_buttons
    @selected_shares.each do |share|
      replace_via_turbo_stream(
        component: Shares::PermissionButtonComponent.new(
          share:,
          available_roles:,
          data: { "test-selector": "op-share-dialog-update-role" }
        )
      )
    end

    respond_with_turbo_streams
  end

  def respond_with_bulk_removed_shares
    @selected_shares.each do |share|
      remove_via_turbo_stream(
        component: Shares::ShareRowComponent.new(
          share:,
          available_roles:,
          sharing_manageable: sharing_manageable?
        )
      )
    end

    update_via_turbo_stream(
      component: Shares::CounterComponent.new(
        entity: @entity,
        count: current_visible_member_count,
        sharing_manageable: sharing_manageable?
      )
    )

    respond_with_turbo_streams
  end

  def load_entity
    @entity = if params["work_package_id"]
                WorkPackage.visible.find(params["work_package_id"])
              elsif params["project_query_id"]
                ProjectQuery.visible.find(params["project_query_id"])
              else
                raise ArgumentError, <<~ERROR
                  Nested the SharesController under an entity controller that is not yet configured to support sharing.
                  Edit the SharesController#load_entity method to load the entity from the correct parent.

                  Params: #{params.to_unsafe_h}
                  Request Path: #{request.path}
                ERROR
              end

    if @entity.respond_to?(:project)
      @project = @entity.project
    end
  end

  def load_share
    @share = @entity.members.find(params[:id])
  end

  def current_visible_member_count
    @current_visible_member_count ||= load_shares.size
  end

  def load_query
    return @query if defined?(@query)

    @query = ParamsToQueryService
               .new(Member, current_user, query_class: Queries::Members::EntityMemberQuery)
               .call(params)

    # Set default filter on the entity
    @query.where("entity_id", "=", @entity.id)
    @query.where("entity_type", "=", @entity.class.name)
    if @project
      @query.where("project_id", "=", @project.id)
    end

    @query.order(name: :asc) unless params[:sortBy]

    @query
  end

  def load_shares
    @shares = load_query.results
  end

  def load_selected_shares
    @selected_shares = Member.includes(:principal)
                             .of_entity(@entity)
                             .where(id: params[:share_ids])
  end

  def available_roles
    @available_roles ||= if @entity.is_a?(WorkPackage)
                           role_mapping = WorkPackageRole.unscoped.pluck(:builtin, :id).to_h

                           [
                             { label: I18n.t("work_package.permissions.edit"),
                               value: role_mapping[Role::BUILTIN_WORK_PACKAGE_EDITOR],
                               description: I18n.t("work_package.permissions.edit_description") },
                             { label: I18n.t("work_package.permissions.comment"),
                               value: role_mapping[Role::BUILTIN_WORK_PACKAGE_COMMENTER],
                               description: I18n.t("work_package.permissions.comment_description") },
                             { label: I18n.t("work_package.permissions.view"),
                               value: role_mapping[Role::BUILTIN_WORK_PACKAGE_VIEWER],
                               description: I18n.t("work_package.permissions.view_description"),
                               default: true }
                           ]
                         elsif @entity.is_a?(ProjectQuery)
                           role_mapping = ProjectQueryRole.unscoped.pluck(:builtin, :id).to_h

                           [
                             { label: I18n.t("work_package.permissions.edit"),
                               value: role_mapping[Role::BUILTIN_PROJECT_QUERY_EDIT],
                               description: I18n.t("work_package.permissions.edit_description") },
                             { label: I18n.t("work_package.permissions.view"),
                               value: role_mapping[Role::BUILTIN_PROJECT_QUERY_VIEW],
                               description: I18n.t("work_package.permissions.view_description"),
                               default: true }
                           ]
                         else

                           []
                         end
  end

  def sharing_contract_scope
    if @entity.is_a?(WorkPackage)
      Shares::WorkPackages
    end
  end

  def sharing_manageable?
    # TODO: Fix this to check based on the entity
    case @entity
    when WorkPackage
      User.current.allowed_in_project?(:share_work_packages, @entity.project)
    when ProjectQuery
      @entity.editable?
    else
      raise ArgumentError, <<~ERROR
        Checking sharing capabilities for an unsupported entity:
        - #{@entity.class}
      ERROR
    end
  end
end
