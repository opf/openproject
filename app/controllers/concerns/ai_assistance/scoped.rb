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

# Shared by the AI Assistance controllers: the feature flag, the place (a work package, a
# project, or neither) and the permission there. A request about a chat or a proposal
# takes the chat's own place. Every chat is looked up through the current user, so nobody
# sees another user's chats.
module AIAssistance::Scoped
  extend ActiveSupport::Concern
  include AIAssistance::RequireFeature

  included do
    before_action :find_place
    before_action :authorize_place
  end

  private

  def find_place
    @named_chat = named_chat
    @place = @named_chat&.place || AI::Assistance::Place.from_params(params, user: current_user)
    return render_404 unless @place&.visible?(current_user)

    @work_package = @place.work_package
    @project = @place.project
  end

  # The user's chat named by chat_id, or the chat of the proposal named by proposal_id.
  def named_chat
    chats = AI::AssistantChat.where(user: current_user)
    if params[:proposal_id].present?
      chats.joins(messages: :proposals).find_by(ai_assistant_proposals: { id: params[:proposal_id] })
    elsif params[:chat_id].present?
      chats.find_by(id: params[:chat_id])
    end
  end

  def authorize_place
    render_403 unless @place.allowed?(current_user)
  end

  def available_skills
    @available_skills ||= AI::AssistantSkill
      .active
      .joins(:assistant)
      .merge(AI::Assistant.active.visible_to(current_user).ordered)
      .includes(:assistant)
      .order(:position, :id)
      .select { |skill| skill.ready? && skill.offered_at?(@place, current_user) }
  end

  # The offered skill with this id.
  def offered_skill(id)
    available_skills.find { |skill| skill.id.to_s == id.to_s }
  end

  # A plain page request (a link opened in a new tab) goes back to the page of the place.
  def respond_with_place_dialog(component)
    respond_with_dialog(component) do |format|
      format.html { redirect_to @place.page_path }
    end
  end

  def respond_with_failure(call)
    render_error_flash_message_via_turbo_stream(message: call.message)
    respond_with_turbo_streams(status: :unprocessable_entity)
  end

  # Applies a proposal of an answer. On success, the header button reloads the work package.
  def apply_proposal(proposal)
    AI::Assistance::ApplyProposalService.new(proposal:, user: current_user).call.tap do |call|
      next unless call.success?

      dispatch_event_via_turbo_stream(WorkPackagesController::UPDATED_EVENT_NAME,
                                      detail: { work_package_id: @work_package.id })
      render_success_flash_message_via_turbo_stream(message: I18n.t("ai_assistance.apply.success"))
    end
  end
end
