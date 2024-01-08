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

class WorkPackages::SharesController < ApplicationController
  include OpTurbo::ComponentStream
  include MemberHelper

  before_action :find_work_package, only: %i[index create resend_invite]
  before_action :find_share, only: %i[destroy update resend_invite]
  before_action :find_project
  before_action :authorize
  before_action :enterprise_check, only: %i[index]

  def index
    query = load_query

    unless query.valid?
      flash.now[:error] = query.errors.full_messages
    end

    @shares = load_shares query

    render WorkPackages::Share::ModalBodyComponent.new(work_package: @work_package, shares: @shares, errors: @errors), layout: nil
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
                         .call(entity: @work_package,
                               user_id: member_params[:user_id],
                               role_ids: find_role_ids(params[:member][:role_id]))

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
      .call(role_ids: find_role_ids(params[:role_ids]))

    find_shares

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

  private

  def enterprise_check
    return if EnterpriseToken.allows_to?(:work_package_sharing)

    render WorkPackages::Share::ModalUpsaleComponent.new
  end

  def respond_with_replace_modal
    replace_via_turbo_stream(
      component: WorkPackages::Share::ModalBodyComponent.new(work_package: @work_package,
                                                             shares: @new_shares || find_shares,
                                                             errors: @errors)
    )

    respond_with_turbo_streams
  end

  def respond_with_prepend_shares
    replace_via_turbo_stream(
      component: WorkPackages::Share::InviteUserFormComponent.new(work_package: @work_package, errors: @errors)
    )

    update_via_turbo_stream(
      component: WorkPackages::Share::CounterComponent.new(work_package: @work_package, count: current_visible_member_count)
    )

    @new_shares.each do |share|
      prepend_via_turbo_stream(
        component: WorkPackages::Share::ShareRowComponent.new(share:),
        target_component: WorkPackages::Share::ModalBodyComponent.new(work_package: @work_package,
                                                                      shares: find_shares,
                                                                      errors: @errors)
      )
    end

    respond_with_turbo_streams
  end

  def respond_with_new_invite_form
    replace_via_turbo_stream(
      component: WorkPackages::Share::InviteUserFormComponent.new(work_package: @work_package, errors: @errors)
    )

    respond_with_turbo_streams
  end

  def respond_with_update_permission_button
    replace_via_turbo_stream(
      component: WorkPackages::Share::PermissionButtonComponent.new(share: @share,
                                                                    data: { 'test-selector': 'op-share-wp-update-role' })
    )

    respond_with_turbo_streams
  end

  def respond_with_remove_share
    remove_via_turbo_stream(
      component: WorkPackages::Share::ShareRowComponent.new(share: @share)
    )

    update_via_turbo_stream(
      component: WorkPackages::Share::CounterComponent.new(work_package: @work_package, count: current_visible_member_count)
    )

    respond_with_turbo_streams
  end

  def respond_with_update_user_details
    update_via_turbo_stream(
      component: WorkPackages::Share::UserDetailsComponent.new(share: @share,
                                                               invite_resent: true)
    )

    respond_with_turbo_streams
  end

  def find_work_package
    @work_package = WorkPackage.find(params[:work_package_id])
  end

  def find_share
    @share = Member.of_any_work_package.find(params[:id])
    @work_package = @share.entity
  end

  def find_shares
    @shares = load_shares(load_query)
  end

  def find_project
    @project = @work_package.project
  end

  def current_visible_member_count
    @current_visible_member_count ||= load_shares(load_query).size
  end

  def load_query
    @query = ParamsToQueryService.new(Member,
                                      current_user,
                                      query_class: Queries::Members::WorkPackageMemberQuery)
                                 .call(params)

    # Set default filter on the entity
    @query.where('entity_id', '=', @work_package.id)
    @query.where('entity_type', '=', WorkPackage.name)
    @query.where('project_id', '=', @project.id)

    @query.order(name: :asc) unless params[:sortBy]

    @query
  end

  def load_shares(query)
    query
      .results
  end
end
