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
  let(:base) { "/work_packages/#{work_package.id}/ai_assistance/chat" }

  current_user { user }

  describe "POST start" do
    subject(:request) { post "#{base}/start", params: { skill_id: skill.id }, as: :turbo_stream }

    it "starts a conversation with the skill's label and opens the chat dialog" do
      expect { request }.to have_enqueued_job(AI::AssistantChats::ReplyJob)

      expect(response).to have_http_status(:ok)
      expect(response).to have_turbo_stream(action: "dialog")
      chat = AI::AssistantChat.for(user, work_package).sole
      expect(chat.messages.map(&:role)).to eq(%w[user assistant])
      expect(chat.messages.first.content).to eq(skill.display_label)
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
        post "#{base}/start", params: { skill_id: personal_skill.id }, as: :turbo_stream

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
end
