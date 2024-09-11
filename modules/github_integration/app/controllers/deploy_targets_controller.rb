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

class DeployTargetsController < ApplicationController
  layout "admin"

  menu_item :admin_github_integration

  before_action :require_admin

  def index
    @deploy_targets = DeployTarget.all
  end

  def new
    @deploy_target = DeployTarget.new type: "OpenProject"
  end

  def create
    args = params
      .permit("deploy_target" => ["host", "type", "api_key"])[:deploy_target]
      .to_h
      .merge(type: "OpenProject")

    @deploy_target = DeployTarget.create **args

    if @deploy_target.persisted?
      flash[:success] = I18n.t(:notice_deploy_target_created)

      redirect_to deploy_targets_path
    else
      render "new"
    end
  end

  def destroy
    deploy_target = DeployTarget.find params[:id]

    deploy_target.destroy!

    flash[:success] = I18n.t(:notice_deploy_target_destroyed)

    redirect_to deploy_targets_path
  end
end
