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

class WorkPackages::AIAssistance::ChatsController < ApplicationController
  include OpTurbo::ComponentStream
  include WorkPackages::AIAssistance::Scoped

  before_action :find_skill, only: %i[create start]
  before_action :find_chat, only: %i[show send_message poll]
  before_action :find_proposal, only: %i[apply]

  # Opens the user's latest chat of this skill about this work package, or an empty one.
  def show
    respond_with_wp_dialog chat_dialog
  end

  # Starts a new, empty chat.
  def create
    @chat = new_chat
    replace_chat
  end

  # A preset: a new conversation whose first question runs the skill's instructions.
  def start
    @chat = new_chat
    call = AI::AssistantChats::SendMessageService.new(chat: @chat, user: current_user).call(@skill.display_label)
    return respond_with_failure(call) if call.failure?

    respond_with_wp_dialog chat_dialog
  end

  def send_message
    @chat ||= new_chat
    call = AI::AssistantChats::SendMessageService.new(chat: @chat, user: current_user).call(params[:content])
    render_error_flash_message_via_turbo_stream(message: call.message) if call.failure?
    replace_chat
  end

  # Polled while an answer is pending. No content until it is done or failed.
  def poll
    return head(:no_content) if @chat.nil? || @chat.pending?

    render turbo_stream: [chat_component, form_component].map { |c| c.render_as_turbo_stream(view_context:, action: :replace) }
  end

  def apply
    call = apply_proposal(@proposal)
    render_error_flash_message_via_turbo_stream(message: call.message) if call.failure?
    replace_chat
  end

  private

  def find_skill
    @skill = offered_skill(params[:skill_id], conversation: true)
    render_404 unless @skill
  end

  # The chat named by chat_id (from History or the open dialog), else the latest chat of
  # the skill named by skill_id. Either way, the skill must still be offered.
  def find_chat
    if params[:chat_id].present?
      @chat = AI::AssistantChat.for(current_user, @work_package).find_by(id: params[:chat_id])
      @skill = offered_skill(@chat&.skill_id, conversation: true)
    else
      @skill = offered_skill(params[:skill_id], conversation: true)
      @chat = AI::AssistantChat.latest_for(current_user, @work_package, @skill) if @skill
    end
    render_404 unless @skill
  end

  def new_chat
    AI::AssistantChat.create!(skill: @skill, user: current_user, work_package: @work_package)
  end

  def find_proposal
    @proposal = AI::AssistantProposal.joins(message: :chat)
                                     .where(ai_assistant_chats: { user_id: current_user.id, work_package_id: @work_package.id })
                                     .find(params.expect(:proposal_id))
    @chat = @proposal.chat
    @skill = offered_skill(@chat.skill_id, conversation: true)
    render_404 unless @skill
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def chat_dialog
    AI::Assistance::ChatDialogComponent.new(work_package: @work_package, skill: @skill, chat: @chat)
  end

  def chat_component
    AI::Assistance::ChatComponent.new(work_package: @work_package, skill: @skill, chat: @chat)
  end

  def form_component
    AI::Assistance::ChatFormComponent.new(work_package: @work_package, skill: @skill, chat: @chat,
                                          dialog_id: AI::Assistance::ChatDialogComponent::DIALOG_ID)
  end

  # The conversation and the footer together: a new question clears the field, and a
  # pending answer disables it.
  def replace_chat
    replace_via_turbo_stream(component: chat_component)
    replace_via_turbo_stream(component: form_component)
    respond_with_turbo_streams
  end
end
