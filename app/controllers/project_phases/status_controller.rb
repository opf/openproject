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

module ProjectPhases
  class StatusController < ApplicationController
    include OpTurbo::ComponentStream
    include OpTurbo::FlashStreamHelper

    before_action :find_phase
    before_action :authorize

    def update
      call = ProjectPhases::UpdateStatusService
        .new(user: current_user, model: @phase)
        .call(status: params.require(:status))

      if call.success?
        reload_frame_via_turbo_stream("project-life-cycle-sidebar")
        respond_with_flash_success(message: t(:notice_successful_update))
      else
        message = t(:notice_unsuccessful_update_with_reason, reason: call.message)
        respond_with_flash_error(message:)
      end
    end

    private

    def find_phase
      @phase = Project::Phase.where(active: true).find(params.expect(:project_phase_id))
      @project = @phase.project
    end
  end
end
