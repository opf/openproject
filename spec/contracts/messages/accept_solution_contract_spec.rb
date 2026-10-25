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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe Messages::AcceptSolutionContract do
  include_context "ModelContract shared context"

  shared_let(:project) { create(:project) }
  shared_let(:forum) { create(:forum, project:) }
  shared_let(:topic_author) { create(:user, member_with_permissions: { project => %i[view_messages] }) }
  shared_let(:topic) { create(:message, forum:, author: topic_author) }

  let(:reply) { create(:message, forum:, parent: topic) }
  let(:message) { reply }
  let(:current_user) { topic_author }

  subject(:contract) { described_class.new(message, current_user) }

  before { message.accepted_solution = true }

  shared_examples "accepting allowed" do
    it_behaves_like "contract is valid"

    it "lets the user accept it" do
      expect(described_class.can_accept?(user: current_user, message:)).to be(true)
    end
  end

  shared_examples "accepting refused" do
    it_behaves_like "contract user is unauthorized"

    it "keeps the user from accepting it" do
      expect(described_class.can_accept?(user: current_user, message:)).to be(false)
    end
  end

  context "for the topic's author" do
    it_behaves_like "accepting allowed"
  end

  context "for a moderator" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_messages edit_messages] }) }

    it_behaves_like "accepting allowed"
  end

  context "for another member" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_messages add_messages] }) }

    it_behaves_like "accepting refused"
  end

  context "for the anonymous user" do
    let(:current_user) { User.anonymous }

    it_behaves_like "accepting refused"
  end

  context "for the opening post" do
    let(:message) { topic }

    it_behaves_like "accepting refused"
  end

  context "when the topic is locked" do
    before { topic.update_column(:locked, true) }

    it_behaves_like "accepting allowed"
  end

  context "when changing anything else" do
    before { message.content = "Rewritten" }

    it_behaves_like "contract is invalid", content: :error_readonly
  end
end
