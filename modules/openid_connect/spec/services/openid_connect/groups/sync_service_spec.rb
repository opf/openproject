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

RSpec.describe OpenIDConnect::Groups::SyncService do
  subject(:call_service) { described_class.new(user:).call(groups_claim:) }

  let(:user) { create(:user, authentication_provider: provider) }
  let(:provider) { create(:oidc_provider) }
  let(:groups_claim) { ["oidc_group_a"] }

  it { is_expected.to be_success }

  it "creates a group" do
    call_service

    expect(Group.first&.name).to eq("oidc_group_a")
  end

  it "links the OIDC group to the local group" do
    call_service
    expect(Group.first.oidc_group_links.where(oidc_group_name: "oidc_group_a", auth_provider: provider)).to be_exist
  end

  it "adds the user to the group" do
    call_service

    expect(user.reload.groups).to include(Group.first)
  end

  it "marks the connection between user and group to be OIDC-related" do
    call_service

    oidc_membership = provider.oidc_group_memberships.first
    expect(oidc_membership).not_to be_nil
    expect(oidc_membership.user).to eq(user)
    expect(oidc_membership.group.name).to eq("oidc_group_a")
  end

  context "when a group already exists" do
    context "and it has the same name" do
      let!(:existing_group) { create(:group, name: "oidc_group_a") }

      it { is_expected.to be_success }

      it "links the OIDC group to the local group" do
        call_service
        expect(existing_group.oidc_group_links.where(oidc_group_name: "oidc_group_a", auth_provider: provider)).to be_exist
      end

      it "adds the user to the existing group" do
        call_service

        expect(user.reload.groups).to include(existing_group)
      end
    end

    context "and it is linked to the OIDC group" do
      let!(:existing_group) { create(:group, name: "local_group_a") }
      let!(:group_link) do
        create(:oidc_group_link, group: existing_group, auth_provider: provider, oidc_group_name: "oidc_group_a")
      end

      it "adds the user to the existing group" do
        call_service

        expect(user.reload.groups).to include(existing_group)
      end
    end
  end

  context "when the user was member of the group before" do
    let!(:existing_group) { create(:group, name: "oidc_group_a", members: [user]) }

    it { is_expected.to be_success }

    it "keeps the user in the group" do
      call_service

      expect(user.reload.groups).to include(existing_group)
    end

    it "marks the connection between user and group to be OIDC-related" do
      call_service

      oidc_membership = provider.oidc_group_memberships.first
      expect(oidc_membership).not_to be_nil
      expect(oidc_membership.user).to eq(user)
      expect(oidc_membership.group.name).to eq("oidc_group_a")
    end

    context "and when the membership was already marked as being OIDC-related" do
      before do
        existing_group.group_users.find_by!(user:).oidc_group_memberships.create!(auth_provider: provider)
      end

      it { is_expected.to be_success }

      it "doesn't mark the connection between user and group to be OIDC-related twice" do
        call_service

        oidc_memberships = existing_group.group_users.find_by!(user:).oidc_group_memberships
        expect(oidc_memberships.count).to eq(1)
      end
    end
  end

  context "when the user was member of a different group before" do
    let!(:existing_group) { create(:group, name: "oidc_group_b", members: [user]) }

    it { is_expected.to be_success }

    it "removes the user from the other group" do
      call_service

      expect(user.reload.groups).not_to include(existing_group)
    end

    context "and that was marked through an OIDC group membership" do
      let!(:membership) do
        existing_group.group_users.find_by(user:).oidc_group_memberships.create!(auth_provider: provider)
      end

      it { is_expected.to be_success }

      it "removes the user from the other group" do
        call_service

        expect(user.reload.groups).not_to include(existing_group)
      end

      it "removes the OIDC group membership as well" do
        expect { call_service }.to change { OpenIDConnect::GroupMembership.where(id: membership.id).count }.from(1).to(0)
      end
    end

    context "and the groups claim adds the user to zero groups" do
      let(:groups_claim) { [] }

      it { is_expected.to be_success }

      it "removes the user from all groups" do
        call_service

        expect(user.reload.groups).to be_empty
      end
    end
  end

  describe "group prefix matching" do
    let(:provider) { create(:oidc_provider, group_prefixes: ["/abc/", "/xyz/"]) }
    let(:groups_claim) { ["/abc/def/ghi", "/abc/ghi/def", "/def/abc/ghi", "/xyz/stu"] }

    it "creates matching groups" do
      expect { call_service }.to change(Group, :count).by(3)
    end

    it "cuts the prefix from the created group names" do
      call_service

      expect(Group.order(:name).pluck(:name)).to eq(["def/ghi", "ghi/def", "stu"])
    end

    it "links the OIDC group to the local group" do
      call_service

      expect(OpenIDConnect::GroupLink.find_by(oidc_group_name: "def/ghi")&.group&.name).to eq("def/ghi")
    end

    context "when prefix captures the full group name" do
      let(:provider) { create(:oidc_provider, group_prefixes: ["/abc/"]) }
      let(:groups_claim) { ["/abc/"] }

      it "creates no group (empty group name)" do
        expect { call_service }.not_to change(Group, :count)
      end
    end
  end

  describe "group regexp matching" do
    let(:provider) { create(:oidc_provider, group_regexes: ["/abc/(.{2})", "/xyz/(.{3})"]) }
    let(:groups_claim) { ["/abc/def/ghi", "abc/123", "/def/abc/ghi", "/xyz/stu"] }

    it "creates matching groups" do
      expect { call_service }.to change(Group, :count).by(3)
    end

    it "uses regular expression groups to determine name" do
      call_service

      expect(Group.order(:name).pluck(:name)).to eq(["de", "gh", "stu"])
    end

    it "links the OIDC group to the local group with correct names on both ends" do
      call_service

      expect(OpenIDConnect::GroupLink.find_by(oidc_group_name: "de")&.group&.name).to eq("de")
    end

    context "when there is no regular expression group" do
      let(:provider) { create(:oidc_provider, group_regexes: ["/abc/"]) }
      let(:groups_claim) { ["/abc/def/ghi", "/xyz/stu"] }

      it "uses the full group name" do
        call_service

        expect(Group.order(:name).pluck(:name)).to eq(["/abc/def/ghi"])
      end
    end

    context "when there are multiple regular expression groups" do
      let(:provider) { create(:oidc_provider, group_regexes: ["/abc/([a-z]+)/([a-z]+)"]) }
      let(:groups_claim) { ["/abc/def/ghi", "/def/abc/ghi/jkl", "/abc/stu"] }

      it "concatenates the match groups" do
        call_service

        expect(Group.order(:name).pluck(:name)).to eq(["defghi", "ghijkl"])
      end
    end

    context "when regex captures an empty group name" do
      let(:provider) { create(:oidc_provider, group_regexes: ["/abc/([a-z]*)"]) }
      let(:groups_claim) { ["/abc/"] }

      it "creates no group" do
        expect { call_service }.not_to change(Group, :count)
      end
    end
  end
end
