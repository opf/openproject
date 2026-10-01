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

RSpec.describe Messages::CreateContract do
  it_behaves_like "message contract" do
    let(:permissions) { %i[add_messages edit_messages] }

    let(:message) do
      Message.new(forum: message_forum,
                  parent: message_parent,
                  subject: message_subject,
                  content: message_content,
                  author: message_author,
                  last_reply: message_last_reply,
                  locked: message_locked,
                  sticky: message_sticky).tap do |m|
        m.extend(OpenProject::ChangedBySystem)
        m.changed_by_system("author_id" => [nil, message_author.id])
      end
    end

    subject(:contract) do
      described_class.new(message, current_user)
    end
  end

  describe "forum assignment" do
    let(:project) { create(:project) }
    let(:forum) { create(:forum, project:) }
    let(:message) do
      Message.new(forum:, subject: "Subject", content: "Content").tap do |m|
        m.extend(OpenProject::ChangedBySystem)
        m.change_by_system { m.author = current_user }
      end
    end

    subject(:contract) { described_class.new(message, current_user) }

    context "with add_messages permission" do
      let(:current_user) do
        create(:user, member_with_permissions: { project => %i[view_messages add_messages] })
      end

      it "is valid" do
        expect(contract).to be_valid
      end
    end

    context "without add_messages permission" do
      let(:current_user) do
        create(:user, member_with_permissions: { project => %i[view_messages] })
      end

      it "is invalid" do
        expect(contract).not_to be_valid
        expect(contract.errors.symbols_for(:forum_id)).to include(:error_readonly)
      end
    end
  end
end
