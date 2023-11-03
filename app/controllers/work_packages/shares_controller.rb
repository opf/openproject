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

  before_action :find_work_package, only: %i[index create]
  before_action :find_share, only: %i[destroy update]
  before_action :find_project
  before_action :authorize

  def index
    query = load_query

    unless query.valid?
      flash.now[:error] = query.errors.full_messages
    end

    @shares = load_shares query

    render WorkPackages::Share::ModalBodyComponent.new(work_package: @work_package, shares: @shares), layout: nil
  end

  def create
    overall_result = []

    find_or_create_users(send_notification: false) do |member_params|
      service_call = WorkPackageMembers::CreateOrUpdateService
                      .new(user: current_user)
                      .call(entity: @work_package,
                            user_id: member_params[:user_id],
                            role_ids: find_role_ids(params[:member][:role_id]))

      @share = service_call.result

      overall_result.push(service_call)
    end

    @shares = overall_result.map(&:result).reverse

    if overall_result.present?
      # In case the number of newly added shares is equal to the whole number of shares,
      # we have to render the whole modal again to get rid of the blankslate
      if current_visible_member_count > 1 && @shares.size < current_visible_member_count
        respond_with_prepend_shares
      else
        respond_with_replace_modal
      end
    end
  end

  def update
    WorkPackageMembers::UpdateService
      .new(user: current_user, model: @share)
      .call(role_ids: find_role_ids(params[:role_ids]))

    respond_with_update_permission_button
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

  private

  def respond_with_replace_modal
    replace_via_turbo_stream(
      component: WorkPackages::Share::ModalBodyComponent.new(work_package: @work_package)
    )

    respond_with_turbo_streams
  end

  def respond_with_prepend_shares
    replace_via_turbo_stream(
      component: WorkPackages::Share::InviteUserFormComponent.new(work_package: @work_package)
    )

    update_via_turbo_stream(
      component: WorkPackages::Share::CounterComponent.new(work_package: @work_package, count: current_visible_member_count)
    )

    @shares.each do |share|
      prepend_via_turbo_stream(
        component: WorkPackages::Share::ShareRowComponent.new(share:),
        target_component: WorkPackages::Share::ModalBodyComponent.new(work_package: @work_package)
      )
    end

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

  def find_work_package
    @work_package = WorkPackage.find(params[:work_package_id])
  end

  def find_share
    @share = Member.of_work_packages.find(params[:id])
    @work_package = @share.entity
  end

  def find_project
    @project = @work_package.project
  end

  def find_role_ids(builtin_value)
    # Role has a left join on permissions included leading to multiple ids being returned which
    # is why we unscope.
    WorkPackageRole.unscoped.where(builtin: builtin_value).pluck(:id)
  end

  def current_visible_member_count
    @current_visible_member_count ||= Member
                                        .joins(:member_roles)
                                        .of_work_package(@work_package)
                                        .merge(MemberRole.only_non_inherited)
                                        .size
  end

  def load_query
    @query = ParamsToQueryService.new(Member, current_user).call(params)

    # Set default filter on the entity
    @query.where('entity_id', '=', @work_package.id)
    @query.where('entity_type', '=', WorkPackage.name)

    @query.order(name: :asc) unless params[:sortBy]

    @query
  end

  def load_shares(query)
    query
      .results
  end
end
