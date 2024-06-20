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
  include MemberHelper

  before_action :load_entity
  before_action :load_shares, only: %i[index]
  before_action :load_selected_shares, only: %i[bulk_update bulk_destroy]
  before_action :load_share, only: %i[destroy update resend_invite]
  before_action :authorize
  before_action :enterprise_check, only: %i[index]

  def index
    unless @query.valid?
      flash.now[:error] = query.errors.full_messages
    end

    render Shares::ModalBodyComponent.new(entity: @entity, shares: @shares, errors: @errors, available_roles:), layout: nil
  end

  def create
    overall_result = []
    @errors = ActiveModel::Errors.new(self)

    find_or_create_users(send_notification: false) do |member_params|
      user = User.find_by(id: member_params[:user_id])
      if user.present? && user.locked?
        @errors.add(:base, I18n.t("work_package.sharing.warning_locked_user", user: user.name))
      else
        service_call = WorkPackageMembers::CreateOrUpdateService
                         .new(user: current_user)
                         .call(entity: @entity,
                               user_id: member_params[:user_id],
                               role_ids: [params[:member][:role_id]])

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
    WorkPackageMembers::UpdateService
      .new(user: current_user, model: @share)
      .call(role_ids: params[:role_ids])

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
    WorkPackageMembers::DeleteService
      .new(user: current_user, model: @share)
      .call

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
    @selected_shares.each do |share|
      WorkPackageMembers::CreateOrUpdateService
        .new(user: current_user)
        .call(entity: @entity,
              user_id: share.principal.id,
              role_ids: params[:role_ids]).result
    end

    respond_with_bulk_updated_permission_buttons
  end

  def bulk_destroy
    @selected_shares.each do |share|
      WorkPackageMembers::DeleteService
        .new(user: current_user, model: share)
        .call
    end

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

  def respond_with_replace_modal
    replace_via_turbo_stream(
      component: Shares::ModalBodyComponent.new(entity: @entity,
                                                available_roles:,
                                                shares: @new_shares || load_shares,
                                                errors: @errors)
    )

    respond_with_turbo_streams
  end

  def respond_with_prepend_shares
    replace_via_turbo_stream(
      component: Shares::InviteUserFormComponent.new(entity: @entity, available_roles:, errors: @errors)
    )

    update_via_turbo_stream(
      component: Shares::CounterComponent.new(entity: @entity, count: current_visible_member_count)
    )

    @new_shares.each do |share|
      prepend_via_turbo_stream(
        component: Shares::ShareRowComponent.new(share:, available_roles:),
        target_component: Shares::ModalBodyComponent.new(entity: @entity,
                                                         available_roles:,
                                                         shares: load_shares,
                                                         errors: @errors)
      )
    end

    respond_with_turbo_streams
  end

  def respond_with_new_invite_form
    replace_via_turbo_stream(component: Shares::InviteUserFormComponent.new(entity: @entity,
                                                                            available_roles:,
                                                                            errors: @errors))

    respond_with_turbo_streams
  end

  def respond_with_update_permission_button
    replace_via_turbo_stream(component: Shares::PermissionButtonComponent.new(share: @share,
                                                                              available_roles:,
                                                                              data: { "test-selector": "op-share-wp-update-role" }))

    respond_with_turbo_streams
  end

  def respond_with_remove_share
    remove_via_turbo_stream(component: Shares::ShareRowComponent.new(share: @share, available_roles:))
    update_via_turbo_stream(component: Shares::CounterComponent.new(entity: @entity, count: current_visible_member_count))

    respond_with_turbo_streams
  end

  def respond_with_update_user_details
    update_via_turbo_stream(component: Shares::UserDetailsComponent.new(share: @share, invite_resent: true))

    respond_with_turbo_streams
  end

  def respond_with_bulk_updated_permission_buttons
    @selected_shares.each do |share|
      replace_via_turbo_stream(
        component: Shares::PermissionButtonComponent.new(share:,
                                                         available_roles:,
                                                         data: { "test-selector": "op-share-wp-update-role" })
      )
    end

    respond_with_turbo_streams
  end

  def respond_with_bulk_removed_shares
    @selected_shares.each do |share|
      remove_via_turbo_stream(
        component: Shares::ShareRowComponent.new(share:, available_roles:)
      )
    end

    update_via_turbo_stream(
      component: Shares::CounterComponent.new(entity: @entity, count: current_visible_member_count)
    )

    respond_with_turbo_streams
  end

  def load_entity
    @entity = if params["work_package_id"]
                WorkPackage.visible.find(params["work_package_id"])
              # TODO: Add support for other entities
              else
                raise ArgumentError, <<~ERROR
                  Nested the SharesController under an entity controller that is not yet configured to support sharing.
                  Edit the SharesController#load_entity method to load the entity from the correct parent.
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

    @query = ParamsToQueryService.new(Member,
                                      current_user,
                                      query_class: Queries::Members::EntityMemberQuery)
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
    # TODO: Optimize loading of roles
    if @entity.is_a?(WorkPackage)
      [
        { label: I18n.t("work_package.sharing.permissions.edit"),
          value: WorkPackageRole.find_by(builtin: Role::BUILTIN_WORK_PACKAGE_EDITOR).id,
          description: I18n.t("work_package.sharing.permissions.edit_description") },
        { label: I18n.t("work_package.sharing.permissions.comment"),
          value: WorkPackageRole.find_by(builtin: Role::BUILTIN_WORK_PACKAGE_COMMENTER).id,
          description: I18n.t("work_package.sharing.permissions.comment_description") },
        { label: I18n.t("work_package.sharing.permissions.view"),
          value: WorkPackageRole.find_by(builtin: Role::BUILTIN_WORK_PACKAGE_VIEWER).id,
          description: I18n.t("work_package.sharing.permissions.view_description"),
          default: true }
      ]
    else
      []
    end
  end
end
