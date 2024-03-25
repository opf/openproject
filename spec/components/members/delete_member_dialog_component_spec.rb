# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
                    shared_work_packages_link:,
                    administration_settings_link:,
                    **stubs)
  end
  let(:shared_work_packages_link) { "[shared work packages link]" }
  let(:administration_settings_link) { "[administration settings link]" }

  before do
    allow(member).to receive(:inherited_shared_work_packages_count?).and_return(true)
  end

  context "when project membership and work package shares can be deleted" do
    let(:stubs) { { can_delete?: true, can_delete_roles?: true, can_delete_shares?: true } }

    it "renders dialog" do
      render_inline(described_class.new(member, row:))

      expect(page).to have_css "dialog"
      expect(page).to have_css "h1", text: "Remove member"

      expect(page).to have_css "scrollable-region", normalize_ws: true, exact_text: <<~TEXT.squish
        This will remove the user’s role from this project. However, [shared work packages link] have also been shared with this user.
        A user that has been removed as member can still access shared work packages. Would you like to remove the shares too?
        (This will not affect work packages shared with their group).
      TEXT

      expect(page).to have_button "Cancel"
      expect(page).to have_css "a.Button", count: 2
      expect(page).to have_css "a.Button", text: "Remove member"
      expect(page).to have_css "a.Button", text: "Remove member and shares"
    end
  end

  context "when project roles and work package shares can be deleted, but not project membership" do
    let(:stubs) { { can_delete?: false, can_delete_roles?: true, can_delete_shares?: true } }

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
    let(:stubs) { { can_delete?: true, can_delete_roles?: true, can_delete_shares?: false } }

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
    let(:stubs) { { can_delete?: false, can_delete_roles?: true, can_delete_shares?: false } }

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
