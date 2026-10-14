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

RSpec.describe AI::AssistantProposal do
  shared_let(:user) { create(:admin) }
  shared_let(:work_package) { create(:work_package, description: "Old text") }

  let(:chat) { create(:ai_assistant_chat, user:, work_package:) }
  let(:message) { create(:ai_assistant_chat_message, chat:) }

  it "orders findings by severity, with plain proposals last" do
    low = create(:ai_assistant_proposal, :finding, message:, severity: "low")
    plain = create(:ai_assistant_proposal, message:)
    high = create(:ai_assistant_proposal, :finding, message:, severity: "high")

    expect(message.proposals.by_severity).to eq([high, low, plain])
    expect(high).to be_finding
    expect(plain).not_to be_finding
  end

  it "counts the open proposals of the whole chat as siblings" do
    first = create(:ai_assistant_proposal, message:)
    other = create(:ai_assistant_proposal, message: create(:ai_assistant_chat_message, chat:))
    create(:ai_assistant_proposal, message: create(:ai_assistant_chat_message))

    expect(first.proposal_siblings).to contain_exactly(first, other)
  end

  it "is applied with a journal cause that names the assistant and the proposal" do
    proposal = create(:ai_assistant_proposal, message:)

    call = User.execute_as(user) { AI::Assistance::ApplyProposalService.new(proposal:, user:).call }

    expect(call).to be_success
    expect(work_package.reload.description).to eq("A better description")
    expect(proposal.reload).to be_applied
    expect(work_package.journals.last.cause).to include("type" => "assistant_chat", "proposal_id" => proposal.id,
                                                        "assistant_name" => chat.skill.assistant.name)
  end
end
