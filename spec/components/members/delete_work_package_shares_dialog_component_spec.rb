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

RSpec.describe Members::DeleteWorkPackageSharesDialogComponent, type: :component do
  let(:member) { build_stubbed(:member, principal:) }
  let(:project) { build_stubbed(:project) }
  let(:principal) { build_stubbed(:principal) }

  let(:table) do
    instance_double(Members::TableComponent, shared_role_name:, shared_role_id:)
  end
  let(:shared_role_name) { "[shared role name]" }
  let(:shared_role_id) { 12345 }

  let(:row) do
    instance_double(Members::RowComponent,
                    table:,
                    project:,
                    principal:,
                    all_shared_work_packages_count:,
                    shared_work_packages_count:,
                    all_shared_work_packages_link:,
                    shared_work_packages_link:,
                    administration_settings_link:,
                    may_manage_user?: may_manage_user?)
  end
  let(:all_shared_work_packages_count) { 5 }
  let(:shared_work_packages_count) { 3 }
  let(:all_shared_work_packages_link) { "[all shared work packages link]" }
  let(:shared_work_packages_link) { "[shared work packages link]" }
  let(:administration_settings_link) { "[administration settings link]" }
  let(:may_manage_user?) { true }

  before do
    without_partial_double_verification do
      allow(member).to receive_messages(stubs)
    end
  end

  context "when there are direct, inherited and shares with filtered out role" do
    let(:stubs) do
      {
        other_shared_work_packages_count?: true,
        direct_shared_work_packages_count?: true,
        inherited_shared_work_packages_count?: true
      }
    end

    it "renders dialog" do
      render_inline(described_class.new(member, row:))

      expect(page).to have_css "dialog"
      expect(page).to have_css "h1", text: "Revoke work package shares"

      expect(page).to have_css "scrollable-region", normalize_ws: true, exact_text: <<~TEXT.squish
        [all shared work packages link] have been shared with this user.
        Only [shared work packages link] have been shared with [shared role name] permissions.
        Would you like to revoke access to all shared work packages, or only those with [shared role name] permissions?
        (This will not affect work packages shared with their group).
      TEXT

      expect(page).to have_button "Cancel"
      expect(page).to have_css "a.Button", count: 2
      expect(page).to have_css "a.Button", text: "Revoke all"
      expect(page).to have_css "a.Button", text: "Revoke only [shared role name]"
    end
  end

  context "when there are direct and shares with filtered out role, but no inherited" do
    let(:stubs) do
      {
        other_shared_work_packages_count?: true,
        direct_shared_work_packages_count?: true,
        inherited_shared_work_packages_count?: false
      }
    end

    context "when principal is a User" do
      let(:principal) { build_stubbed(:user) }

      it "renders dialog" do
        render_inline(described_class.new(member, row:))

        expect(page).to have_css "dialog"
        expect(page).to have_css "h1", text: "Revoke work package shares"

        expect(page).to have_css "scrollable-region", normalize_ws: true, exact_text: <<~TEXT.squish
          [all shared work packages link] have been shared with this user.
          Only [shared work packages link] have been shared with [shared role name] permissions.
          Would you like to revoke access to all shared work packages, or only those with [shared role name] permissions?
        TEXT

        expect(page).to have_button "Cancel"
        expect(page).to have_css "a.Button", count: 2
        expect(page).to have_css "a.Button", text: "Revoke all"
        expect(page).to have_css "a.Button", text: "Revoke only [shared role name]"
      end
    end

    context "when principal is a Group" do
      let(:principal) { build_stubbed(:group) }

      it "renders dialog" do
        render_inline(described_class.new(member, row:))

        expect(page).to have_css "dialog"
        expect(page).to have_css "h1", text: "Revoke work package shares"

        expect(page).to have_css "scrollable-region", normalize_ws: true, exact_text: <<~TEXT.squish
          [all shared work packages link] have been shared with this group.
          Only [shared work packages link] have been shared with [shared role name] permissions.
          Would you like to revoke access to all shared work packages, or only those with [shared role name] permissions?
        TEXT

        expect(page).to have_button "Cancel"
        expect(page).to have_css "a.Button", count: 2
        expect(page).to have_css "a.Button", text: "Revoke all"
        expect(page).to have_css "a.Button", text: "Revoke only [shared role name]"
      end
    end
  end

  context "when there are shares with filtered out role, but no direct" do
    let(:stubs) do
      {
        other_shared_work_packages_count?: true,
        direct_shared_work_packages_count?: false
      }
    end

    it "renders dialog" do
      render_inline(described_class.new(member, row:))

      expect(page).to have_css "dialog"
      expect(page).to have_css "h1", text: "Revoke work package shares"

      expect(page).to have_css "scrollable-region", normalize_ws: true, exact_text: <<~TEXT.squish
        The work packages shares with role [shared role name] are shared via groups and cannot be removed.
        You can either revoke the share to the group or remove this specific member from the group in the [administration settings link].
      TEXT

      expect(page).to have_button "Cancel"
      expect(page).to have_no_css "a.Button"
    end
  end

  context "when there are direct and inherited shares, but no ones with filtered out role" do
    let(:stubs) do
      {
        other_shared_work_packages_count?: false,
        direct_shared_work_packages_count?: true,
        inherited_shared_work_packages_count?: true
      }
    end

    it "renders dialog" do
      render_inline(described_class.new(member, row:))

      expect(page).to have_css "dialog"
      expect(page).to have_css "h1", text: "Revoke work package shares"

      expect(page).to have_css "scrollable-region", normalize_ws: true, exact_text: <<~TEXT.squish
        [all shared work packages link] have been shared with this user.
        This action will revoke their access to all of them, but the work packages shared with a group.
      TEXT

      expect(page).to have_button "Cancel"
      expect(page).to have_css "a.Button", count: 1
      expect(page).to have_css "a.Button", text: "Revoke access"
    end
  end

  context "when there are direct shares, but no inherited or ones with filtered out role" do
    let(:stubs) do
      {
        other_shared_work_packages_count?: false,
        direct_shared_work_packages_count?: true,
        inherited_shared_work_packages_count?: false
      }
    end

    context "when principal is a User" do
      let(:principal) { build_stubbed(:user) }

      it "renders dialog" do
        render_inline(described_class.new(member, row:))

        expect(page).to have_css "dialog"
        expect(page).to have_css "h1", text: "Revoke work package shares"

        expect(page).to have_css "scrollable-region", normalize_ws: true, exact_text: <<~TEXT.squish
          [all shared work packages link] have been shared with this user.
          This action will revoke their access to all of them.
        TEXT

        expect(page).to have_button "Cancel"
        expect(page).to have_css "a.Button", count: 1
        expect(page).to have_css "a.Button", text: "Revoke access"
      end
    end

    context "when principal is a Group" do
      let(:principal) { build_stubbed(:group) }

      it "renders dialog" do
        render_inline(described_class.new(member, row:))

        expect(page).to have_css "dialog"
        expect(page).to have_css "h1", text: "Revoke work package shares"

        expect(page).to have_css "scrollable-region", normalize_ws: true, exact_text: <<~TEXT.squish
          [all shared work packages link] have been shared with this group.
          This action will revoke their access to all of them.
        TEXT

        expect(page).to have_button "Cancel"
        expect(page).to have_css "a.Button", count: 1
        expect(page).to have_css "a.Button", text: "Revoke access"
      end
    end
  end

  context "when there are no direct or shares with filtered out role" do
    let(:stubs) do
      {
        other_shared_work_packages_count?: false,
        direct_shared_work_packages_count?: false
      }
    end

    it "renders dialog" do
      render_inline(described_class.new(member, row:))

      expect(page).to have_css "dialog"
      expect(page).to have_css "h1", text: "Revoke work package shares"

      expect(page).to have_css "scrollable-region", normalize_ws: true, exact_text: <<~TEXT.squish
        The work packages shares shared via groups cannot be removed.
        You can either revoke the share to the group or remove this specific member from the group in the [administration settings link].
      TEXT

      expect(page).to have_button "Cancel"
      expect(page).to have_no_css "a.Button"
    end
  end
end
