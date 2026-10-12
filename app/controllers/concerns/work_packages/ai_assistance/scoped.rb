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

# Shared by the AI Assistance controllers: the feature flag, the work package and the
# permission. Every run and chat is looked up through the current user, so nobody sees
# another user's runs or chats.
module WorkPackages::AIAssistance::Scoped
  extend ActiveSupport::Concern
  include AIAssistance::RequireFeature

  included do
    before_action :find_work_package
    before_action :authorize
  end

  private

  def find_work_package
    @work_package = WorkPackage.visible.find(params[:work_package_id])
    @project = @work_package.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def runs
    AI::AssistantRun.for(current_user, @work_package)
  end

  def find_run
    @run = runs.find(params[:ai_assistance_run_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def available_skills
    AI::AssistantSkill
      .active
      .joins(:assistant)
      .merge(AI::Assistant.active)
      .includes(:assistant)
      .order("ai_assistants.position", "ai_assistants.id", :position, :id)
      .select(&:ready?)
  end

  # Applies a finding or a chat answer. On success, the toolbar reloads the work package.
  def apply_proposal(proposal)
    AI::Assistance::ApplyProposalService.new(proposal:, user: current_user).call.tap do |call|
      next unless call.success?

      dispatch_event_via_turbo_stream(WorkPackagesController::UPDATED_EVENT_NAME,
                                      detail: { work_package_id: @work_package.id })
      render_success_flash_message_via_turbo_stream(message: I18n.t("ai_assistance.apply.success"))
    end
  end
end
