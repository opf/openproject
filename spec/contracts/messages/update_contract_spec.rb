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
require_relative "shared_contract_examples"

RSpec.describe Messages::UpdateContract do
  it_behaves_like "message contract" do
    let(:message) do
      build_stubbed(:message).tap do |message|
        message.forum = message_forum
        message.parent = message_parent
        message.subject = message_subject
        message.content = message_content
        message.last_reply = message_last_reply
        message.locked = message_locked
        message.sticky = message_sticky
      end
    end
    subject(:contract) { described_class.new(message, current_user) }

    context "if the author is changed" do
      it "is invalid" do
        message.author = other_user
        expect_valid(false, author_id: %i(error_readonly))
      end
    end
  end

  context "when moving a message to another forum" do
    let(:project) { create(:project) }
    let(:forum) { create(:forum, project: project) }
    let(:other_forum) { create(:forum, project: project) }
    let(:message) { create(:message, forum: forum) }
    let(:forum_in_other_project) { create(:forum) }

    let(:current_user) { create(:user, member_with_permissions: { project => [:edit_messages] }) }

    subject(:contract) { described_class.new(message, current_user) }

    context "when moving the message to another forum in the same project" do
      before do
        message.forum = other_forum
      end

      it "is valid" do
        expect(contract).to be_valid
      end
    end

    context "when moving the message to a forum in another project" do
      before do
        message.forum = forum_in_other_project
      end

      it "is invalid" do
        expect(contract).not_to be_valid
        expect(contract.errors[:forum_id]).to include("A message cannot be moved to a forum of a different project.")
      end
    end

    context "when the user only has edit_own_messages" do
      let(:current_user) do
        create(:user, member_with_permissions: { project => %i[view_messages edit_own_messages] })
      end
      let(:message) { create(:message, forum:, author: current_user) }

      before do
        message.forum = other_forum
      end

      it "is invalid" do
        expect(contract).not_to be_valid
        expect(contract.errors.symbols_for(:forum_id)).to include(:error_readonly)
      end
    end
  end
end
