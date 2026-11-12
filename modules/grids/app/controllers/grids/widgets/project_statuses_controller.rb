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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Grids::Widgets::ProjectStatusesController < Grids::WidgetController
  def show
    render_widget Grids::Widgets::ProjectStatus.new(@project, current_user:)
  end

  def update
    call = Projects::UpdateService
      .new(model: @project, user: current_user)
      .call(permitted_params.project_status)

    if call.success?
      @project = call.result
      update_via_turbo_stream(component: Grids::Widgets::ProjectStatus.new(@project, current_user:))
      render_success_flash_message_via_turbo_stream(message: t(:notice_successful_update))
      respond_with_turbo_streams
    else
      respond_with_flash_error(message: t(:notice_unsuccessful_update_with_reason, reason: call.message))
    end
  end
end
