# frozen_string_literal: true

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

class WorkPackages::Shares::BulkController < ApplicationController
  include OpTurbo::ComponentStream
  include MemberHelper

  before_action :find_work_package
  before_action :find_selected_shares
  before_action :find_role_ids_from_params, only: :update
  before_action :find_project
  before_action :authorize

  def update
    @selected_shares.each do |share|
      WorkPackageMembers::CreateOrUpdateService
        .new(user: current_user)
        .call(entity: @work_package,
              user_id: share.principal.id,
              role_ids: @role_ids).result
    end

    respond_with_update_permission_buttons
  end

  def destroy
    @selected_shares.each do |share|
      WorkPackageMembers::DeleteService
        .new(user: current_user, model: share)
        .call
    end

    if current_visible_member_count.zero?
      respond_with_replace_modal
    else
      respond_with_remove_shares
    end
  end

  private

  def respond_with_update_permission_buttons
    @selected_shares.each do |share|
      replace_via_turbo_stream(
        component: WorkPackages::Share::PermissionButtonComponent.new(share:,
                                                                      data: { 'test-selector': 'op-share-wp-update-role' })
      )
    end

    respond_with_turbo_streams
  end

  def respond_with_replace_modal
    replace_via_turbo_stream(
      component: WorkPackages::Share::ModalBodyComponent.new(work_package: @work_package, shares: find_shares)
    )

    respond_with_turbo_streams
  end

  def respond_with_remove_shares
    @selected_shares.each do |share|
      remove_via_turbo_stream(
        component: WorkPackages::Share::ShareRowComponent.new(share:)
      )
    end

    update_via_turbo_stream(
      component: WorkPackages::Share::CounterComponent.new(work_package: @work_package, count: current_visible_member_count)
    )

    respond_with_turbo_streams
  end

  def find_work_package
    @work_package = WorkPackage.find(params[:work_package_id])
  end

  def find_project
    @project = @work_package.project
  end

  def find_shares
    @shares = Member.includes(:principal, :member_roles)
                    .references(:member_roles)
                    .of_work_package(@work_package)
                    .merge(MemberRole.only_non_inherited)
  end

  def find_selected_shares
    @selected_shares = Member.includes(:principal)
                             .of_work_package(@work_package)
                             .where(id: params[:share_ids])
  end

  def find_role_ids_from_params
    @role_ids = find_role_ids(params[:role_ids])
  end

  def current_visible_member_count
    @current_visible_member_count ||= Member
                                        .joins(:member_roles)
                                        .of_work_package(@work_package)
                                        .merge(MemberRole.only_non_inherited)
                                        .size
  end
end
