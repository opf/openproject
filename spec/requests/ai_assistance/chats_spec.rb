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

require "spec_helper"

RSpec.describe "AI Assistance chats", :skip_csrf, type: :rails_request, with_flag: { ai_assistance: true } do
  include_context "with an available LLM for AI Assistance"

  shared_let(:project) { create(:project) }
  shared_let(:skill) { create(:ai_assistant_skill) }

  let(:permissions) { %i[view_work_packages edit_work_packages use_ai_assistance] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:work_package) { create(:work_package, project:, description: "Old text") }
  let(:base) { "/ai_assistance/chat" }
  let(:place) { { work_package_id: work_package.id } }

  current_user { user }

  describe "POST start" do
    subject(:request) { post "#{base}/start", params: { **place, skill_id: skill.id }, as: :turbo_stream }

    it "starts a conversation without a question and opens the chat dialog" do
      expect { request }.to have_enqueued_job(AI::AssistantChats::ReplyJob)

      expect(response).to have_http_status(:ok)
      expect(response).to have_turbo_stream(action: "dialog")
      chat = AI::AssistantChat.for(user, AI::Assistance::Place.new(work_package:)).sole
      expect(chat.messages.map(&:role)).to eq(%w[start assistant])
    end

    context "when the last start of the skill is still answering" do
      it "opens that chat and starts nothing new" do
        post "#{base}/start", params: { **place, skill_id: skill.id }, as: :turbo_stream

        expect { request }.not_to have_enqueued_job(AI::AssistantChats::ReplyJob)

        expect(response).to have_turbo_stream(action: "dialog")
        expect(AI::AssistantChat.for(user, AI::Assistance::Place.new(work_package:)).sole.messages.count).to eq(2)
      end

      it "starts a new chat once the answer is done" do
        post "#{base}/start", params: { **place, skill_id: skill.id }, as: :turbo_stream
        AI::AssistantChatMessage.pending.update_all(status: "done")

        expect { request }.to have_enqueued_job(AI::AssistantChats::ReplyJob)
        expect(AI::AssistantChat.for(user, AI::Assistance::Place.new(work_package:)).count).to eq(2)
      end
    end

    context "without the permission" do
      let(:permissions) { %i[view_work_packages] }

      it "is forbidden and stores nothing" do
        request

        expect(response).to have_http_status(:forbidden)
        expect(AI::AssistantChat.count).to eq(0)
      end
    end

    context "with a personal skill of another user" do
      let(:owner) { create(:user, global_permissions: %i[manage_own_ai_assistants]) }
      let(:personal_skill) { create(:ai_assistant_skill, :preset, assistant: create(:ai_assistant, principal: owner)) }

      it "responds with not found and stores nothing" do
        post "#{base}/start", params: { **place, skill_id: personal_skill.id }, as: :turbo_stream

        expect(response).to have_http_status(:not_found)
        expect(AI::AssistantChat.count).to eq(0)
      end
    end

    context "when the skill is inactive" do
      before { skill.update!(active: false) }

      after { skill.update!(active: true) }

      it "responds with not found" do
        request

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with the feature flag off", with_flag: { ai_assistance: false } do
      it "responds with not found" do
        request

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST rerun" do
    let(:chat) { create(:ai_assistant_chat, skill:, user:, work_package:) }

    before do
      create(:ai_assistant_chat_message, chat:, role: "start", content: "")
      create(:ai_assistant_chat_message, chat:)
    end

    it "starts the skill again in the same chat" do
      expect { post "#{base}/rerun", params: { chat_id: chat.id }, as: :turbo_stream }
        .to have_enqueued_job(AI::AssistantChats::ReplyJob)

      expect(chat.messages.reload.map(&:role)).to eq(%w[start assistant start assistant])
    end

    context "with a chat skill" do
      let(:chat) { create(:ai_assistant_chat, skill: create(:ai_assistant_skill, :chat), user:, work_package:) }

      it "responds with not found" do
        post "#{base}/rerun", params: { chat_id: chat.id }, as: :turbo_stream

        expect(response).to have_http_status(:not_found)
        expect(chat.messages.count).to eq(2)
      end
    end
  end

  describe "GET poll" do
    let(:chat) { create(:ai_assistant_chat, skill:, user:, work_package:) }
    let!(:answer) { create(:ai_assistant_chat_message, chat:, status: "pending", content: "") }

    before do
      answer.log_event(:tool_call, name: "count_work_packages", arguments: { project_id: project.id, open: true },
                                   seconds: 0.1, size: 12)
    end

    it "shows the tool calls of a pending answer, without the form" do
      get "#{base}/poll", params: { chat_id: chat.id, reference: "0" }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Count work packages (open: true, project_id: #{project.id})")
      expect(response.body).to include(%(data-poll-for-changes-reference-value="1"))
      expect(response.body).not_to include(AI::Assistance::ChatFormComponent.wrapper_key)
    end

    it "answers with no content while nothing new happened" do
      get "#{base}/poll", params: { chat_id: chat.id, reference: "1" }, as: :turbo_stream

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET show with a chat_id" do
    let(:chat) { create(:ai_assistant_chat, skill:, user:, work_package:) }
    let!(:answer) { create(:ai_assistant_chat_message, chat:) }

    before { create(:ai_assistant_proposal, message: answer) }

    it "opens the chat with the form and the Apply button" do
      get base, params: { chat_id: chat.id }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-test-selector="ai-assistance-chat-form"', 'data-test-selector="ai-assistance-apply"')
    end

    context "when the skill is not offered any more" do
      before { skill.update!(active: false) }

      after { skill.update!(active: true) }

      it "opens the chat read-only" do
        get base, params: { chat_id: chat.id }, as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("ai-assistance-chat-read-only", answer.content)
        %w[ai-assistance-chat-form ai-assistance-apply ai-assistance-dismiss].each do |selector|
          expect(response.body).not_to include(%(data-test-selector="#{selector}"))
        end
      end

      it "does not accept a new question" do
        post "#{base}/messages", params: { chat_id: chat.id, content: "More?" }, as: :turbo_stream

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with another user's chat" do
      let(:chat) { create(:ai_assistant_chat, skill:, work_package:) }

      it "responds with not found" do
        get base, params: { chat_id: chat.id }, as: :turbo_stream

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET history" do
    let!(:own_chat) { create(:ai_assistant_chat, skill:, user:, work_package:) }
    let!(:other_chat) { create(:ai_assistant_chat, skill:, work_package:) }

    before do
      create(:ai_assistant_chat_message, chat: own_chat, role: "user", content: "Mine")
      create(:ai_assistant_chat_message, chat: other_chat, role: "user", content: "Theirs")
    end

    it "lists only the user's chats" do
      get "#{base}/history", params: place, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("chat_id=#{own_chat.id}")
      expect(response.body).not_to include("chat_id=#{other_chat.id}")
    end
  end

  describe "a proposal" do
    let(:chat) { create(:ai_assistant_chat, skill:, user:, work_package:) }
    let(:message) { create(:ai_assistant_chat_message, chat:) }
    let(:proposal) { create(:ai_assistant_proposal, :finding, message:) }

    it "is applied" do
      post "#{base}/proposals/#{proposal.id}/apply", as: :turbo_stream

      expect(proposal.reload).to be_applied
      expect(work_package.reload.description).to eq("A better description")
    end

    it "is dismissed with the reason, and an unknown reason is ignored" do
      post "#{base}/proposals/#{proposal.id}/dismiss", params: { reason: "wrong" }, as: :turbo_stream

      expect(proposal.reload).to have_attributes(state: "dismissed", dismiss_reason: "wrong")

      other = create(:ai_assistant_proposal, message:)
      post "#{base}/proposals/#{other.id}/dismiss", params: { reason: "bored" }, as: :turbo_stream

      expect(other.reload).to have_attributes(state: "dismissed", dismiss_reason: nil)
    end

    context "with another user's chat" do
      let(:chat) { create(:ai_assistant_chat, skill:, work_package:) }

      it "responds with not found" do
        post "#{base}/proposals/#{proposal.id}/dismiss", as: :turbo_stream

        expect(response).to have_http_status(:not_found)
        expect(proposal.reload).to be_open
      end
    end
  end

  describe "a chat off a work package" do
    let(:chat_skill) { create(:ai_assistant_skill, :chat, assistant: skill.assistant, offered_on: "everywhere") }

    it "opens an empty chat on a project page and stores the question with the project" do
      get base, params: { project_id: project.identifier, skill_id: chat_skill.id }, as: :turbo_stream
      expect(response).to have_turbo_stream(action: "dialog")
      expect(response.body).to include(I18n.t("ai_assistance.chat.empty_title_generic"))

      params = { project_id: project.identifier, skill_id: chat_skill.id, content: "Hi" }
      expect { post "#{base}/messages", params:, as: :turbo_stream }.to have_enqueued_job(AI::AssistantChats::ReplyJob)

      chat = AI::AssistantChat.where(user:).sole
      expect(chat).to have_attributes(project:, work_package: nil)
    end

    it "keeps a chat without a project apart from the project's chats" do
      create(:ai_assistant_chat, skill: chat_skill, user:, work_package: nil, project:)

      post "#{base}/messages", params: { skill_id: chat_skill.id, content: "Hi" }, as: :turbo_stream

      expect(AI::AssistantChat.where(user:, project: nil, work_package: nil).count).to eq(1)
    end

    it "does not offer a work package skill" do
      post "#{base}/start", params: { project_id: project.identifier, skill_id: skill.id }, as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "History across places" do
    let(:chat_skill) { create(:ai_assistant_skill, :chat, assistant: skill.assistant, offered_on: "everywhere") }
    let!(:work_package_chat) { create(:ai_assistant_chat, skill:, user:, work_package:) }
    let!(:project_chat) { create(:ai_assistant_chat, skill: chat_skill, user:, work_package: nil, project:) }

    before do
      create(:ai_assistant_chat_message, chat: work_package_chat)
      create(:ai_assistant_chat_message, chat: project_chat, role: "user", content: "About the project")
    end

    it "lists all the user's chats with their place" do
      get "#{base}/history", as: :turbo_stream

      expect(response.body).to include(work_package.formatted_id, project.name, "About the project")
    end

    it "opens a work package chat from a page without a project" do
      get base, params: { chat_id: work_package_chat.id }, as: :turbo_stream

      expect(response).to have_turbo_stream(action: "dialog")
      expect(response.body).to include('data-test-selector="ai-assistance-chat-form"')
    end
  end
end
