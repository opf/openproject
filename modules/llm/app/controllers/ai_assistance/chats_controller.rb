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

class AIAssistance::ChatsController < ApplicationController
  include OpTurbo::ComponentStream
  include AIAssistance::Scoped

  READABLE = %w[show poll].freeze

  # By authorize_place: the permission at the place of the request or of its chat.
  authorization_checked! :show, :create, :start, :rerun, :send_message, :poll, :history, :apply, :dismiss

  before_action :find_skill, only: %i[create start]
  before_action :find_chat, only: %i[show send_message poll rerun]
  before_action :find_proposal, only: %i[apply dismiss]

  # All the user's chats, newest first. Each opens here, in its own place.
  def history
    chats = AI::AssistantChat.where(user: current_user).includes(:messages, :work_package, :project, skill: :assistant)
    respond_with_place_dialog AI::Assistance::HistoryDialogComponent.new(chats:)
  end

  # Opens the user's latest chat of this skill at this place, or an empty one.
  def show
    respond_with_place_dialog chat_dialog
  end

  # Starts a new, empty chat.
  def create
    @chat = new_chat
    replace_chat
  end

  # A new conversation that the skill answers at once. While the user's last start of this
  # skill here is still answering, it opens that chat instead (a double click, a second tab).
  def start
    call = OpenProject::Mutex.with_advisory_lock_transaction(current_user, start_lock_name) do
      @chat = running_chat
      next ServiceResult.success if @chat

      @chat = new_chat
      AI::AssistantChats::SendMessageService.new(chat: @chat, user: current_user).start
    end
    return respond_with_failure(call) if call.failure?

    respond_with_place_dialog chat_dialog
  end

  # Starts the skill again in the same chat, on the current state of its place.
  def rerun
    return render_404 if @chat.nil? || @skill.chat?

    call = AI::AssistantChats::SendMessageService.new(chat: @chat, user: current_user).start
    render_error_flash_message_via_turbo_stream(message: call.message) if call.failure?
    replace_chat
  end

  def send_message
    @chat ||= new_chat
    call = AI::AssistantChats::SendMessageService.new(chat: @chat, user: current_user).call(params[:content])
    render_error_flash_message_via_turbo_stream(message: call.message) if call.failure?
    replace_chat
  end

  # Polled while an answer is pending. No content until it is done or failed.
  def poll
    @chat&.fail_stale_answers!
    return head(:no_content) if @chat.nil?
    return poll_progress if @chat.pending?

    render turbo_stream: [chat_component, form_component].map { |c| c.render_as_turbo_stream(view_context:, action: :replace) }
  end

  def apply
    call = apply_proposal(@proposal)
    render_error_flash_message_via_turbo_stream(message: call.message) if call.failure?
    replace_chat
  end

  # With an optional reason: wrong, not relevant or already known.
  def dismiss
    reason = params.fetch(:reason, nil).presence_in(AI::AssistantProposal.dismiss_reasons.keys)
    @proposal.update!(state: "dismissed", dismiss_reason: reason) if @proposal.open?
    replace_chat
  end

  private

  # While an answer is pending, only the conversation is replaced, and only when it has new
  # events (the tool calls so far). The form keeps what the user types.
  def poll_progress
    return head(:no_content) if params[:reference] == AI::Assistance::ChatComponent.progress_reference(@chat)

    render turbo_stream: chat_component.render_as_turbo_stream(view_context:, action: :replace)
  end

  def find_skill
    @skill = offered_skill(params[:skill_id])
    render_404 unless @skill
  end

  # The chat named by chat_id (from History, the activity or the open dialog), else the
  # latest chat of the skill named by skill_id. A skill that is no longer offered can
  # only be read.
  def find_chat
    if params[:chat_id].present?
      find_named_chat
    else
      @skill = offered_skill(params[:skill_id])
      @chat = AI::AssistantChat.latest_for(current_user, @place, @skill) if @skill
    end
    render_404 unless @skill
  end

  def find_named_chat
    @chat = @named_chat
    @skill = offered_skill(@chat&.skill_id)
    @read_only = !@skill && @chat.present? && READABLE.include?(action_name)
    @skill = @chat.skill if @read_only
  end

  def start_lock_name
    "ai_start_#{@work_package&.id}_#{@project&.id}_#{@skill.id}"
  end

  def running_chat
    chat = AI::AssistantChat.for(current_user, @place).where(skill: @skill).with_pending_answer.order(id: :desc).first
    chat&.fail_stale_answers!
    chat if chat&.pending?
  end

  def new_chat
    AI::AssistantChat.create!(skill: @skill, user: current_user, work_package: @work_package, project: @project)
  end

  def find_proposal
    @chat = @named_chat
    @proposal = @chat && AI::AssistantProposal.joins(:message).where(message: { chat_id: @chat.id })
                                              .find_by(id: params[:proposal_id])
    @skill = offered_skill(@chat&.skill_id)
    render_404 unless @proposal && @skill
  end

  def component_arguments
    { place: @place, skill: @skill, chat: @chat, read_only: @read_only }
  end

  def chat_dialog
    AI::Assistance::ChatDialogComponent.new(**component_arguments)
  end

  def chat_component
    AI::Assistance::ChatComponent.new(**component_arguments)
  end

  def form_component
    AI::Assistance::ChatFormComponent.new(**component_arguments, dialog_id: AI::Assistance::ChatDialogComponent::DIALOG_ID)
  end

  # The conversation and the footer together: a new question clears the field, and a
  # pending answer disables it.
  def replace_chat
    replace_via_turbo_stream(component: chat_component)
    replace_via_turbo_stream(component: form_component)
    respond_with_turbo_streams
  end
end
