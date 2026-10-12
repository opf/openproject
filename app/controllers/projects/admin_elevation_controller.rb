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

class Projects::AdminElevationController < ApplicationController
  include OpTurbo::ComponentStream

  before_action :require_admin
  before_action :find_project_by_project_id

  def new
    respond_with_dialog AdminElevationSessions::ElevateDialogComponent.new(project: @project, back_url: params[:back_url])
  end

  def create
    call = elevate

    if call.success?
      flash[:notice] = I18n.t("admin_elevation.notice_elevated", project: @project.name)
    else
      flash[:error] = call.message
    end

    redirect_back_or_default(project_path(@project), status: :see_other)
  end

  private

  def elevate
    AdminElevationSessions::CreateService
      .new(user: current_user)
      .call(project: @project,
            session_id: session.id.private_id,
            confirmed_with: "confirmation",
            include_subprojects:)
  end

  def include_subprojects
    ActiveModel::Type::Boolean.new.cast(params.dig(:admin_elevation, :include_subprojects)) || false
  end
end
