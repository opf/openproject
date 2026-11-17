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
require_module_spec_helper

RSpec.describe AI::AssistantChats::SendMessageService do
  let(:chat) { create(:ai_assistant_chat) }
  let(:service) { described_class.new(chat:, user: chat.user) }

  it "stores the question and a pending answer, and starts the reply job" do
    expect { service.call("Hello") }.to have_enqueued_job(AI::AssistantChats::ReplyJob)

    expect(chat.messages.reload.map { |message| [message.role, message.status] })
      .to eq([%w[user done], %w[assistant pending]])
  end

  it "refuses a question while an answer is pending" do
    service.call("Hello")

    result = described_class.new(chat: chat.reload, user: chat.user).call("Again")

    expect(result).to be_failure
    expect(chat.messages.count).to eq(2)
  end

  it "refuses a second pending answer that a parallel request stored first" do
    stale_view = AI::AssistantChat.find(chat.id).tap { |copy| copy.messages.load }
    service.call("Hello")

    result = nil
    expect { result = described_class.new(chat: stale_view, user: chat.user).call("Again") }
      .not_to have_enqueued_job(AI::AssistantChats::ReplyJob)

    expect(result).to be_failure
    expect(chat.messages.reload.where(status: "pending").count).to eq(1)
    expect(chat.messages.count).to eq(2)
  end
end
