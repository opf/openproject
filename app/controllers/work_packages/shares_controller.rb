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

  before_action :find_work_package

  # Todo: access control

  def index
    render WorkPackages::Share::ModalComponent.new(work_package: @work_package), layout: nil
  end

  def create
    # Todo: Role selection, error handling?
    WorkPackageMembers::CreateService
      .new(user: current_user)
      .call(entity: @work_package,
            user_id: params[:member][:user_id],
            roles: Role.where(builtin: Role::BUILTIN_WORK_PACKAGE_VIEWER))

    replace_via_turbo_stream(
      component: WorkPackages::Share::ModalComponent.new(work_package: @work_package)
    )

    respond_with_turbo_streams
  end

  # Todo: Delete

  private

  def find_work_package
    @work_package = WorkPackage.find(params[:work_package_id])
  end
end
