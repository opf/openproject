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

RSpec.describe Groups::Scopes::ContainingUser do
  describe ".containing_user" do
    shared_let(:user1) { create(:user, firstname: "User", lastname: "One") }
    shared_let(:user2) { create(:user, firstname: "User", lastname: "Two") }
    shared_let(:user3) { create(:user, firstname: "User", lastname: "Three") }

    shared_let(:group1) { create(:group, lastname: "Group One") }
    shared_let(:group2) { create(:group, lastname: "Group Two") }
    shared_let(:group3) { create(:group, lastname: "Group Three") }

    before do
      User.system.run_given do |system_user|
        Groups::AddUsersService
          .new(group1, current_user: system_user)
          .call(ids: [user1.id, user2.id], send_notifications: false)

        Groups::AddUsersService
          .new(group2, current_user: system_user)
          .call(ids: [user2.id], send_notifications: false)

        # group3 has no users
      end
    end

    context "when called with a specific user" do
      it "returns only groups containing that user" do
        expect(Group.containing_user(user1)).to contain_exactly(group1)
      end

      it "returns multiple groups if user is in multiple groups" do
        expect(Group.containing_user(user2)).to contain_exactly(group1, group2)
      end

      it "returns empty if user is not in any group" do
        expect(Group.containing_user(user3)).to be_empty
      end
    end

    context "when called without arguments" do
      current_user { user1 }

      it "uses User.current and returns groups containing the current user" do
        expect(Group.containing_user).to contain_exactly(group1)
      end
    end

    context "when current user is in multiple groups" do
      current_user { user2 }

      it "returns all groups containing the current user" do
        expect(Group.containing_user).to contain_exactly(group1, group2)
      end
    end

    context "when current user is not in any group" do
      current_user { user3 }

      it "returns empty" do
        expect(Group.containing_user).to be_empty
      end
    end
  end
end
