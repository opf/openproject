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

  before_action :find_work_package, only: %i[index create]
  before_action :find_share, only: %i[destroy update]
  before_action :find_project
  before_action :authorize

  def index
    render WorkPackages::Share::ModalBodyComponent.new(work_package: @work_package), layout: nil
  end

  def create
    @share = WorkPackageMembers::CreateOrUpdateService
      .new(user: current_user)
      .call(entity: @work_package,
            user_id: params[:member][:user_id],
            role_ids: find_role_ids(params[:member][:role_id])).result


    if current_member_count > 1
      respond_with_prepend_share
    else
      respond_with_replace_modal
    end
  end

  def update
    WorkPackageMembers::UpdateService
      .new(user: current_user, model: @share)
      .call(role_ids: find_role_ids(params[:role_ids]))

    head :no_content
  end

  def destroy
    WorkPackageMembers::DeleteService
      .new(user: current_user, model: @share)
      .call

    if current_member_count.zero?
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

  def respond_with_prepend_share
    replace_via_turbo_stream(
      component: WorkPackages::Share::InviteUserFormComponent.new(work_package: @work_package)
    )

    update_via_turbo_stream(
      component: WorkPackages::Share::ShareCounterComponent.new(count: current_member_count)
    )

    prepend_via_turbo_stream(
      component: WorkPackages::Share::ShareRowComponent.new(share: @share),
      target_component: WorkPackages::Share::ModalBodyComponent.new(work_package: @work_package)
    )

    respond_with_turbo_streams
  end

  def respond_with_remove_share
    remove_via_turbo_stream(
      component: WorkPackages::Share::ShareRowComponent.new(share: @share)
    )

    update_via_turbo_stream(
      component: WorkPackages::Share::ShareCounterComponent.new(count: current_member_count)
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

  def current_member_count
    @current_member_count ||= Member.of_work_package(@work_package).size
  end
end
