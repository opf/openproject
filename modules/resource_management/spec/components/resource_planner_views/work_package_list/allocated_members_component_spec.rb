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

RSpec.describe ResourcePlannerViews::WorkPackageList::AllocatedMembersComponent, type: :component do
  shared_let(:work_package) { create(:work_package) }
  shared_let(:assignee) { create(:user, firstname: "Michael", lastname: "Johnson") }

  def assigned_allocation(principal)
    create(:resource_allocation, entity: work_package, principal:)
  end

  def filter_allocation(name)
    create(:resource_allocation,
           entity: work_package,
           principal_explicit: false,
           principal: nil,
           filter_name: name)
  end

  # nil means no visibility restriction (every principal is visible).
  let(:visible_principal_ids) { nil }

  subject(:rendered) do
    render_inline(described_class.new(allocations:, visible_principal_ids:))
    page
  end

  before { login_as(create(:admin)) }

  context "with a single assigned member" do
    let(:allocations) { [assigned_allocation(assignee)] }

    it "renders an avatar stack with the member's name and no extra count" do
      expect(rendered).to have_css(".AvatarStack")
      expect(rendered).to have_css("avatar-fallback[data-unique-id='#{assignee.id}'][data-alt-text='Michael Johnson']")
      expect(rendered).to have_text("Michael Johnson")
      expect(rendered).to have_no_text("+")
    end
  end

  context "with several members" do
    let(:others) { create_list(:user, 2) }
    let(:allocations) { [assigned_allocation(assignee), *others.map { |u| assigned_allocation(u) }] }

    it "stacks an avatar per member and shows the lead name with a +N count of the rest" do
      expect(rendered).to have_css("avatar-fallback", count: 3)
      expect(rendered).to have_text("Michael Johnson")
      expect(rendered).to have_text("+2")
    end
  end

  context "with exactly two members" do
    let(:allocations) { [assigned_allocation(assignee), assigned_allocation(create(:user))] }

    it "shows the lead name and a +1 count" do
      expect(rendered).to have_css("avatar-fallback", count: 2)
      expect(rendered).to have_text("Michael Johnson")
      expect(rendered).to have_text("+1")
    end
  end

  context "with a filter-based allocation that has no assigned user" do
    let(:allocations) { [filter_allocation("Full stack Developer (DE-EN)")] }

    it "renders a generated avatar keyed to the allocation, labelled with the filter name" do
      expect(rendered).to have_css("avatar-fallback[data-unique-id='resource-allocation-#{allocations.first.id}']")
      expect(rendered).to have_css("avatar-fallback[data-alt-text='Full stack Developer (DE-EN)']")
      expect(rendered).to have_text("Full stack Developer (DE-EN)")
    end
  end

  context "with an allocation whose principal was removed" do
    # Mimics `dependent: :nullify` after the assigned user is deleted: an
    # explicit allocation left without a principal and without a filter name.
    let(:allocations) do
      allocation = assigned_allocation(assignee)
      allocation.update_column(:principal_id, nil)
      [allocation]
    end

    it "renders a generated 'Unassigned' avatar instead of raising" do
      label = I18n.t("resource_management.work_package_list.allocated_members.unassigned")
      expect(rendered).to have_css("avatar-fallback[data-alt-text='#{label}']")
      expect(rendered).to have_text(label)
    end
  end

  context "with a member the current user cannot see" do
    let(:hidden_user) { create(:user, firstname: "Hidden", lastname: "Person") }
    let(:allocations) { [assigned_allocation(assignee), assigned_allocation(hidden_user)] }
    let(:visible_principal_ids) { Set[assignee.id] }

    it "names only the visible member but still counts the hidden one" do
      expect(rendered).to have_css("avatar-fallback[data-unique-id='#{assignee.id}']")
      expect(rendered).to have_text("Michael Johnson")
      expect(rendered).to have_text("+1")
    end

    it "does not reveal the hidden member's avatar or name" do
      expect(rendered).to have_no_css("avatar-fallback[data-unique-id='#{hidden_user.id}']")
      expect(rendered).to have_no_text("Hidden Person")
    end
  end

  context "when every member is hidden from the current user" do
    let(:allocations) { [assigned_allocation(assignee), assigned_allocation(create(:user))] }
    let(:visible_principal_ids) { Set.new }

    it "shows an anonymous count instead of names or avatars" do
      expect(rendered).to have_no_css("avatar-fallback")
      expect(rendered).to have_no_text("Michael Johnson")
      expect(rendered).to have_text("2 users")
    end
  end

  context "without any allocations" do
    let(:allocations) { [] }

    it "renders nothing" do
      expect(rendered).to have_no_css(".AvatarStack")
      expect(rendered).to have_no_css("avatar-fallback")
    end
  end
end
