# -- copyright
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
# ++

class SharesController < ApplicationController
  include OpTurbo::ComponentStream
  include OpTurbo::DialogStreamHelper
  include MemberHelper

  before_action :load_entity
  before_action :load_selected_shares, only: %i[bulk_update bulk_destroy]
  before_action :load_share, only: %i[destroy update resend_invite]

  before_action :check_if_manageable, except: %i[index dialog]
  before_action :check_if_viewable, only: %i[index dialog]
  authorization_checked! :dialog, :index, :create, :update, :destroy, :resend_invite, :bulk_update, :bulk_destroy

  def dialog; end

  def index
    unless sharing_strategy.query.valid?
      flash.now[:error] = sharing_strategy.query.errors.full_messages
    end

    render sharing_strategy.modal_body_component(@errors), layout: nil
  end

  def create # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
    overall_result = []
    @errors = ActiveModel::Errors.new(self)

    visible_shares_before_adding = sharing_strategy.shares.present?

    find_or_create_users(send_notification: send_notification?) do |member_params|
      user = User.find_by(id: member_params[:user_id])
      if user.present? && user.locked?
        @errors.add(:base, I18n.t("sharing.warning_locked_user", user: user.name))
      else
        service_call = create_or_update_share(member_params[:user_id], [params[:member][:role_id]])
        overall_result.push(service_call)
      end
    end

    new_shares = overall_result.map(&:result).reverse

    if overall_result.present?
      # In case we did not have shares before we have to replace the modal to get rid of the blankstate,
      # otherwise we can prepend the new shares
      if visible_shares_before_adding
        respond_with_prepend_shares(new_shares)
      else
        respond_with_replace_modal
      end
    else
      respond_with_new_invite_form
    end
  end

  def update
    create_or_update_share(@share.principal.id, params[:role_ids])

    shares = sharing_strategy.shares(reload: true)

    if shares.empty?
      respond_with_replace_modal
    elsif shares.include?(@share)
      respond_with_update_permission_button
    else
      respond_with_remove_share
    end
  end

  def destroy
    destroy_share(@share)

    # When we removed the last share we have to replace the modal to show the blankstate
    if sharing_strategy.shares(reload: true).empty?
      respond_with_replace_modal
    else
      respond_with_remove_share
    end
  end

  # TODO: This is still work package specific
  def resend_invite
    OpenProject::Notifications.send(OpenProject::Events::WORK_PACKAGE_SHARED,
                                    work_package_member: @share,
                                    send_notifications: true)

    respond_with_update_user_details
  end

  def bulk_update
    @selected_shares.each { |share| create_or_update_share(share.principal.id, params[:role_ids]) }

    respond_with_bulk_updated_permission_buttons(@selected_shares)
  end

  def bulk_destroy
    @selected_shares.each { |share| destroy_share(share) }

    if sharing_strategy.shares(reload: true).empty?
      respond_with_replace_modal
    else
      respond_with_bulk_removed_shares(@selected_shares)
    end
  end

  private

  attr_reader :sharing_strategy

  def check_if_viewable
    return if sharing_strategy.viewable? || sharing_strategy.manageable?

    render_403
  end

  def check_if_manageable
    return if sharing_strategy.manageable?

    render_403
  end

  def destroy_share(share)
    Shares::DeleteService
      .new(user: current_user, model: share, contract_class: sharing_strategy.delete_contract_class)
      .call
  end

  def create_or_update_share(user_id, role_ids)
    Shares::CreateOrUpdateService.new(
      user: current_user,
      create_contract_class: sharing_strategy.create_contract_class,
      update_contract_class: sharing_strategy.update_contract_class
    ).call(entity: @entity, user_id:, role_ids:)
  end

  def respond_with_replace_modal
    sharing_strategy.shares(reload: true)

    replace_via_turbo_stream(component: sharing_strategy.modal_body_component(@errors))

    respond_with_turbo_streams
  end

  def respond_with_prepend_shares(new_shares)
    replace_via_turbo_stream(
      component: Shares::InviteUserFormComponent.new(
        strategy: sharing_strategy,
        errors: @errors
      )
    )

    update_via_turbo_stream(
      component: Shares::CounterComponent.new(
        strategy: sharing_strategy,
        count: sharing_strategy.shares(reload: true).count
      )
    )

    new_shares.each do |share|
      prepend_via_turbo_stream(
        component: Shares::ShareRowComponent.new(share:, strategy: sharing_strategy),
        target_component: Shares::ManageSharesComponent.new(strategy: sharing_strategy, modal_content: nil, errors: @errors)
      )
    end

    respond_with_turbo_streams
  end

  def respond_with_new_invite_form
    replace_via_turbo_stream(
      component: Shares::InviteUserFormComponent.new(
        strategy: sharing_strategy,
        errors: @errors
      )
    )

    respond_with_turbo_streams
  end

  def respond_with_update_permission_button
    replace_via_turbo_stream(
      component: Shares::PermissionButtonComponent.new(
        share: @share,
        strategy: sharing_strategy,
        data: { "test-selector": "op-share-dialog-update-role" }
      )
    )

    respond_with_turbo_streams
  end

  def respond_with_remove_share
    remove_via_turbo_stream(
      component: Shares::ShareRowComponent.new(
        share: @share,
        strategy: sharing_strategy
      )
    )
    update_via_turbo_stream(
      component: Shares::CounterComponent.new(
        strategy: sharing_strategy,
        count: sharing_strategy.shares(reload: true).count
      )
    )

    respond_with_turbo_streams
  end

  def respond_with_update_user_details
    update_via_turbo_stream(
      component: Shares::UserDetailsComponent.new(
        share: @share,
        strategy: sharing_strategy,
        invite_resent: true
      )
    )

    respond_with_turbo_streams
  end

  def respond_with_bulk_updated_permission_buttons(selected_shares)
    selected_shares.each do |share|
      replace_via_turbo_stream(
        component: Shares::PermissionButtonComponent.new(
          share:,
          strategy: sharing_strategy,
          data: { "test-selector": "op-share-dialog-update-role" }
        )
      )
    end

    respond_with_turbo_streams
  end

  def respond_with_bulk_removed_shares(selected_shares)
    selected_shares.each do |share|
      remove_via_turbo_stream(
        component: Shares::ShareRowComponent.new(
          share:,
          strategy: sharing_strategy
        )
      )
    end

    update_via_turbo_stream(
      component: Shares::CounterComponent.new(
        count: sharing_strategy.shares(reload: true).count,
        strategy: sharing_strategy
      )
    )

    respond_with_turbo_streams
  end

  def send_notification?
    return false if @entity.is_a?(WorkPackage) # For WorkPackages we have a custom notification

    true
  end

  def load_entity # rubocop:disable Metrics/AbcSize
    if params["work_package_id"]
      @entity = WorkPackage.visible.find(params["work_package_id"])
      @sharing_strategy = SharingStrategies::WorkPackageStrategy.new(@entity, user: current_user, query_params:)
    elsif params["project_query_id"]
      @entity = ProjectQuery.visible.find(params["project_query_id"])
      @sharing_strategy = SharingStrategies::ProjectQueryStrategy.new(@entity, user: current_user, query_params:)
    else
      raise ArgumentError, <<~ERROR
        Nested the SharesController under an entity controller that is not yet configured to support sharing.
        Edit the SharesController#load_entity method to load the entity from the correct parent and specify what sharing
        strategy should be applied.

        Params: #{params.to_unsafe_h}
        Request Path: #{request.path}
      ERROR
    end
  end

  def load_share
    @share = @entity.members.find(params[:id])
  end

  def load_selected_shares
    @selected_shares = Member.includes(:principal)
                             .of_entity(@entity)
                             .where(id: params[:share_ids])
  end

  def query_params
    params
      .slice(:filters, :sortBy, :groupBy)
      .permit! # ParamsToQueryService will parse the data, so we can permit everything here
  end
end
