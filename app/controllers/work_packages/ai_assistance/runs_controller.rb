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

class WorkPackages::AIAssistance::RunsController < ApplicationController
  include OpTurbo::ComponentStream
  include WorkPackages::AIAssistance::Scoped

  before_action :find_run, only: %i[show poll]

  # Both open a dialog. A plain page request (a link opened in a new tab) goes back to
  # the work package instead of failing.
  def index
    chats = AI::AssistantChat.for(current_user, @work_package).includes(:messages, skill: :assistant)
    respond_with_dialog AI::Assistance::HistoryDialogComponent.new(work_package: @work_package,
                                                                   runs: runs.newest_first.includes(skill: :assistant),
                                                                   chats:) do |format|
      format.html { redirect_to work_package_path(@work_package) }
    end
  end

  def show
    respond_with_dialog AI::Assistance::RunDialogComponent.new(run: @run) do |format|
      format.html { redirect_to work_package_path(@work_package) }
    end
  end

  # Polled by the run dialog while the AI judgement runs. No content until the run is
  # finished; then the whole run is replaced, which also stops the polling.
  def poll
    return head(:no_content) unless @run.terminal?

    render turbo_stream: AI::Assistance::RunComponent.new(run: @run)
                                                      .render_as_turbo_stream(view_context:, action: :replace)
  end

  def create
    skill = available_skills.find { |s| !s.chat? && s.id.to_s == params[:skill_id].to_s }
    return render_404 unless skill

    call = AI::AssistantRuns::RunService.new(skill:, work_package: @work_package, user: current_user).call

    if call.success?
      respond_with_dialog AI::Assistance::RunDialogComponent.new(run: call.result)
    else
      render_error_flash_message_via_turbo_stream(message: call.message)
      respond_with_turbo_streams(status: :unprocessable_entity)
    end
  end
end
