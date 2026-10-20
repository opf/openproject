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
    respond_with_dialog elevate_dialog
  end

  def create
    if current_user.password_checkable? && !current_user.check_password?(params.dig(:admin_elevation, :password))
      return respond_with_dialog(elevate_dialog(password_error: I18n.t(:notice_password_confirmation_failed)),
                                 status: :unprocessable_entity)
    end

    call = elevate

    if call.success?
      flash[:notice] = I18n.t("admin_elevation.notice_elevated", project: @project.name)
    else
      flash[:error] = call.message
    end

    redirect_back_or_default(project_path(@project), status: :see_other)
  end

  def destroy
    current_admin_elevation_sessions.covering(@project).find_each do |elevation_session|
      AdminElevationSessions::EndService.new(user: current_user, model: elevation_session).call
    end

    flash[:notice] = I18n.t("admin_elevation.notice_ended", project: @project.name)
    redirect_to project_path(@project), status: :see_other
  end

  private

  def elevate_dialog(password_error: nil)
    AdminElevationSessions::ElevateDialogComponent.new(project: @project,
                                                       user: current_user,
                                                       back_url: params[:back_url],
                                                       include_subprojects:,
                                                       password_error:)
  end

  def elevate
    AdminElevationSessions::CreateService
      .new(user: current_user)
      .call(project: @project,
            session_id: session.id.private_id,
            confirmed_with: current_user.password_checkable? ? "password" : "confirmation",
            include_subprojects:)
  end

  def include_subprojects
    ActiveModel::Type::Boolean.new.cast(params.dig(:admin_elevation, :include_subprojects)) || false
  end
end
