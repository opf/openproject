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

require "rails_helper"

RSpec.describe Members::DeleteMemberDialogComponent, type: :component do
  let(:member) { build_stubbed(:member, principal:) }
  let(:project) { build_stubbed(:project) }
  let(:principal) { build_stubbed(:principal) }

  let(:row) do
    instance_double(Members::RowComponent,
                    project:,
                    principal:,
                    shared_work_packages_count:,
                    shared_work_packages_link:,
                    administration_settings_link:,
                    may_manage_user?: may_manage_user?,
                    **stubs)
  end
  let(:shared_work_packages_count) { 3 }
  let(:shared_work_packages_link) { "[shared work packages link]" }
  let(:administration_settings_link) { "[administration settings link]" }
  let(:may_manage_user?) { true }

  context "when project membership and work package shares can be deleted" do
    let(:stubs) { { can_delete?: true, can_delete_roles?: true, may_delete_shares?: true, shared_work_packages?: true } }

    context "when principal is a User" do
      let(:principal) { build_stubbed(:user) }

      before do
        without_partial_double_verification do
          allow(member).to receive(:inherited_shared_work_packages_count?).and_return(true)
        end
      end

      it "renders dialog" do
        render_inline(described_class.new(member, row:))

        expect(page).to have_css "dialog"
        expect(page).to have_css "h1", text: "Remove member"

        expect(page).to have_css "scrollable-region", normalize_ws: true, exact_text: <<~TEXT.squish
          This will remove the user’s role from this project.
          However, [shared work packages link] have also been shared with this user.
          A user that has been removed as member can still access shared work packages. Would you like to remove the shares too?
          (This will not affect work packages shared with their group).
        TEXT

        expect(page).to have_button "Cancel"
        expect(page).to have_css "a.Button", count: 2
        expect(page).to have_css "a.Button", text: "Remove member"
        expect(page).to have_css "a.Button", text: "Remove member and shares"
      end
    end

    context "when principal is a Group" do
      let(:principal) { build_stubbed(:group) }

      it "renders dialog" do
        render_inline(described_class.new(member, row:))

        expect(page).to have_css "dialog"
        expect(page).to have_css "h1", text: "Remove member"

        expect(page).to have_css "scrollable-region", normalize_ws: true, exact_text: <<~TEXT.squish
          This will remove the group role from this project.
          However, [shared work packages link] have also been shared with this group.
          A group that has been removed as member can still access shared work packages. Would you like to remove the shares too?
        TEXT

        expect(page).to have_button "Cancel"
        expect(page).to have_css "a.Button", count: 2
        expect(page).to have_css "a.Button", text: "Remove member"
        expect(page).to have_css "a.Button", text: "Remove member and shares"
      end
    end
  end

  context "when project roles and work package shares can be deleted, but not project membership" do
    let(:stubs) { { can_delete?: false, can_delete_roles?: true, may_delete_shares?: true, shared_work_packages?: true } }

    before do
      without_partial_double_verification do
        allow(member).to receive(:inherited_shared_work_packages_count?).and_return(true)
      end
    end

    it "renders dialog" do
      render_inline(described_class.new(member, row:))

      expect(page).to have_css "dialog"
      expect(page).to have_css "h1", text: "Remove member"

      expect(page).to have_css "scrollable-region", normalize_ws: true, exact_text: <<~TEXT.squish
        You can remove this user as a direct project member but a group they are in is also a member of this project, so they will continue being a member via the group.
        Also, [shared work packages link] have been shared with this user.
        Do you want to remove just the user as a direct member (and keep the shares) or remove the work package shares too?
        (This will not affect work packages shared with their group).
      TEXT

      expect(page).to have_button "Cancel"
      expect(page).to have_css "a.Button", count: 2
      expect(page).to have_css "a.Button", text: "Remove member"
      expect(page).to have_css "a.Button", text: "Remove member and shares"
    end
  end

  context "when project membership can be deleted, but not work package shares" do
    let(:stubs) { { can_delete?: true, can_delete_roles?: true, may_delete_shares?: false } }

    it "renders dialog" do
      render_inline(described_class.new(member, row:))

      expect(page).to have_css "dialog"
      expect(page).to have_css "h1", text: "Remove member"

      expect(page).to have_css "scrollable-region", normalize_ws: true, exact_text: <<~TEXT.squish
        Deleting this member will remove all access privileges of the user to the project. The user will still exist as part of the instance.
      TEXT

      expect(page).to have_button "Cancel"
      expect(page).to have_css "a.Button", count: 1
      expect(page).to have_css "a.Button", text: "Remove"
    end
  end

  context "when project roles can be deleted, but not project membership or work package shares" do
    let(:stubs) { { can_delete?: false, can_delete_roles?: true, may_delete_shares?: false } }

    it "renders dialog" do
      render_inline(described_class.new(member, row:))

      expect(page).to have_css "dialog"
      expect(page).to have_css "h1", text: "Remove member"

      expect(page).to have_css "scrollable-region", normalize_ws: true, exact_text: <<~TEXT.squish
        You can remove this user as a direct project member but a group they are in is also a member of this project, so they will continue being a member via the group.
      TEXT

      expect(page).to have_button "Cancel"
      expect(page).to have_css "a.Button", count: 1
      expect(page).to have_css "a.Button", text: "Remove"
    end
  end

  context "when project roles can not be deleted" do
    let(:stubs) { { can_delete_roles?: false } }

    it "renders dialog" do
      render_inline(described_class.new(member, row:))

      expect(page).to have_css "dialog"
      expect(page).to have_css "h1", text: "Remove member"

      expect(page).to have_css "scrollable-region", normalize_ws: true, exact_text: <<~TEXT.squish
        You cannot delete this member because they belong to a group that is itself a member of this project.
        You can either remove the group as a member of the project or this specific member from the group in the [administration settings link].
      TEXT

      expect(page).to have_button "Cancel"
      expect(page).to have_no_css "a.Button"
    end
  end
end
