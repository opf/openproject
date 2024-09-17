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

RSpec.describe Principal do
  let(:user) { build(:user) }
  let(:group) { build(:group) }

  def self.should_return_groups_and_users_if_active(method, *)
    it "returns a user" do
      user.save!

      expect(described_class.send(method, *).where(id: user.id)).to eq([user])
    end

    it "returns a group" do
      group.save!

      expect(described_class.send(method, *).where(id: group.id)).to eq([group])
    end

    it "does not return the anonymous user" do
      User.anonymous

      expect(described_class.send(method, *).where(id: user.id)).to eq([])
    end

    it "does not return an inactive user" do
      user.status = User.statuses[:locked]

      user.save!

      expect(described_class.send(method, *).where(id: user.id).to_a).to eq([])
    end
  end

  describe "associations" do
    subject { described_class.new }

    it { is_expected.to have_many(:work_package_shares).conditions(entity_type: WorkPackage.name) }
  end

  describe "active" do
    should_return_groups_and_users_if_active(:active)

    it "does not return a registered user" do
      user.status = User.statuses[:registered]

      user.save!

      expect(described_class.active.where(id: user.id)).to eq([])
    end
  end

  describe "not_locked" do
    should_return_groups_and_users_if_active(:not_locked)

    it "returns a registered user" do
      user.status = User.statuses[:registered]

      user.save!

      expect(described_class.not_locked.where(id: user.id)).to eq([user])
    end
  end

  describe ".memberships" do
    let(:project_role) { create(:project_role) }
    let(:global_role) { create(:global_role) }
    let(:work_package_role) { create(:view_work_package_role) }
    let(:user) { create(:user) }
    let!(:active_project_member) do
      create(:member,
             principal: user,
             project: create(:project),
             roles: [project_role])
    end
    let!(:inactive_project_member) do
      create(:member,
             principal: user,
             project: create(:project, active: false),
             roles: [project_role])
    end
    let!(:global_member) do
      create(:member,
             principal: user,
             project: nil,
             roles: [global_role])
    end
    let!(:work_package_member) do
      create(:work_package_member,
             principal: user,
             project: create(:project),
             entity: create(:work_package),
             roles: [work_package_role])
    end

    it "returns all active projects and global members" do
      expect(user.memberships)
        .to contain_exactly(active_project_member, global_member)
    end
  end

  describe "#name" do
    shared_let(:user_id) { create(:user, firstname: "John", lastname: "Smith", login: "john_smith").id }
    shared_let(:group_id) { create(:group, name: "Folk").id }
    shared_let(:placeholder_user_id) { create(:placeholder_user, name: "Wannabejohn").id }

    shared_examples "name formatting" do
      context "for lastname_coma_firstname formatter", with_settings: { user_format: :lastname_coma_firstname } do
        it "returns formatted user name" do
          expect(user.name).to eq "Smith, John"
        end

        it "returns formatted group name" do
          expect(group.name).to eq "Folk"
        end

        it "returns formatted placeholder user name" do
          expect(placeholder_user.name).to eq "Wannabejohn"
        end
      end

      context "for username formatter", with_settings: { user_format: :username } do
        it "returns formatted user name" do
          expect(user.name).to eq "john_smith"
        end

        it "returns formatted group name" do
          expect(group.name).to eq "Folk"
        end

        it "returns formatted placeholder user name" do
          expect(placeholder_user.name).to eq "Wannabejohn"
        end
      end
    end

    context "when fetched individually" do
      let(:user) { User.select_for_name.find(user_id) }
      let(:group) { Group.select_for_name.find(group_id) }
      let(:placeholder_user) { PlaceholderUser.select_for_name.find(placeholder_user_id) }

      include_examples "name formatting"
    end

    context "when fetched as Principal" do
      let(:user) { described_class.select(:type).select_for_name.find(user_id) }
      let(:group) { described_class.select(:type).select_for_name.find(group_id) }
      let(:placeholder_user) { described_class.select(:type).select_for_name.find(placeholder_user_id) }

      include_examples "name formatting"
    end
  end
end
