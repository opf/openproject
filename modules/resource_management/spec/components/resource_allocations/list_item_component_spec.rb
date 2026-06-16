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

RSpec.describe ResourceAllocations::ListItemComponent, type: :component do
  shared_let(:work_package) { create(:work_package) }
  shared_let(:member) { create(:user, firstname: "Sarah", lastname: "Smith") }

  let(:visible) { true }
  let(:overbooked) { false }
  let(:editable) { false }

  subject(:rendered) do
    render_inline(described_class.new(allocation:, project: work_package.project, visible:, overbooked:, editable:))
    page
  end

  before { login_as(create(:admin)) }

  context "with a visible assigned member" do
    let(:allocation) { create(:resource_allocation, entity: work_package, principal: member, allocated_time: 720) }

    it "shows the member's name, avatar and allocated hours" do
      expect(rendered).to have_text("Sarah Smith")
      expect(rendered).to have_css(".Label", text: "12h")
      expect(rendered).to have_css("avatar-fallback[data-unique-id='#{member.id}']")
      expect(rendered).to have_no_css(".octicon-alert-fill")
    end
  end

  context "with an overbooked assigned member" do
    let(:allocation) { create(:resource_allocation, entity: work_package, principal: member, allocated_time: 720) }
    let(:overbooked) { true }

    it "shows a danger warning icon" do
      expect(rendered).to have_css(".octicon-alert-fill#resource-allocation-overbooked-#{allocation.id}")
    end
  end

  context "when the user may manage allocations" do
    let(:allocation) { create(:resource_allocation, entity: work_package, principal: member, allocated_time: 720) }
    let(:editable) { true }

    it "offers an edit/delete menu" do
      expect(rendered).to have_css("action-menu")
      expect(rendered).to have_css("a[href*='/resource_allocations/#{allocation.id}/edit']", visible: :all)
      expect(rendered).to have_button(I18n.t(:button_delete), visible: :all)
    end
  end

  context "when the user may manage allocations but not see the member" do
    let(:allocation) { create(:resource_allocation, entity: work_package, principal: member, allocated_time: 720) }
    let(:editable) { true }
    let(:visible) { false }

    it "offers no menu, since editing would reveal the hidden user" do
      expect(rendered).to have_no_css("action-menu")
    end
  end

  context "when the user may not manage allocations" do
    let(:allocation) { create(:resource_allocation, entity: work_package, principal: member, allocated_time: 720) }

    it "offers no menu" do
      expect(rendered).to have_no_css("action-menu")
    end
  end

  context "with an assigned member the user may not see" do
    let(:allocation) { create(:resource_allocation, entity: work_package, principal: member, allocated_time: 720) }
    let(:visible) { false }

    it "anonymises the member without revealing the name" do
      expect(rendered).to have_no_text("Sarah Smith")
      expect(rendered).to have_no_css("avatar-fallback[data-unique-id='#{member.id}']")
      expect(rendered).to have_text(I18n.t("resource_management.work_package_allocations_dialog.hidden_user"))
    end
  end

  context "with a filter-based allocation" do
    let(:allocation) do
      create(:resource_allocation,
             entity: work_package, principal_explicit: false, principal: nil, filter_name: "Full stack developer")
    end

    it "shows the filter name with a person-add icon instead of an avatar" do
      expect(rendered).to have_text("Full stack developer")
      expect(rendered).to have_css(".octicon-person-add")
      expect(rendered).to have_no_css("avatar-fallback")
    end
  end
end
