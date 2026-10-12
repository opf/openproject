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

class WorkPackages::AIAssistance::FindingsController < ApplicationController
  include OpTurbo::ComponentStream
  include WorkPackages::AIAssistance::Scoped

  before_action :find_run
  before_action :find_finding

  def apply
    call = AI::AssistantRuns::ApplyProposalService.new(proposal: @finding, user: current_user).call

    if call.success?
      dispatch_event_via_turbo_stream(WorkPackagesController::UPDATED_EVENT_NAME,
                                      detail: { work_package_id: @work_package.id })
      render_success_flash_message_via_turbo_stream(message: I18n.t("ai_assistance.apply.success"))
    end

    replace_via_turbo_stream(component: AI::Assistance::FindingComponent.new(finding: @finding.reload,
                                                                              error: call.failure? ? call.result : nil))
    respond_with_turbo_streams
  end

  def dismiss
    reason = params[:reason].presence_in(AI::AssistantRunFinding.dismiss_reasons.keys)
    @finding.update!(state: "dismissed", dismiss_reason: reason) if @finding.open?

    replace_via_turbo_stream(component: AI::Assistance::FindingComponent.new(finding: @finding))
    respond_with_turbo_streams
  end

  private

  def find_finding
    @finding = @run.findings.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
