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

RSpec.describe My::Work::AllocationActionMenuComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking costs]) }

  let(:permissions) { %i[view_project view_work_packages edit_work_packages work_package_assigned log_own_time] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:assignee) { nil }
  let(:work_package) { create(:work_package, project:, assigned_to: assignee) }
  let(:date) { Date.new(2026, 10, 5) }
  let(:visible) { true }
  let(:navigation) { false }
  let(:allocation) do
    resource_allocation = build_stubbed(:resource_allocation, entity: work_package, principal: user)
    entry = ResourceAllocations::ScheduledEntry.new(allocation: resource_allocation, work_package:,
                                                    allocated_on: date, minutes: 360)

    My::Work::AllocationRow::Entry.new(scheduled_entry: entry, visible:, hours: 4.5)
  end

  current_user { user }

  subject(:rendered_component) { render_inline(described_class.new(allocation:, navigation:)) }

  it "offers to assign the work package" do
    expect(rendered_component).to have_link("Assign work package to me", href: "/work_packages/#{work_package.id}/assign_to_me")
  end

  it "offers to log what is left of the allocation" do
    rendered_component
    link = page.find_link("Log time from allocation")

    expect(link[:href]).to include("work_package_id=#{work_package.id}", "date=2026-10-05", "hours=4.5")
  end

  it "leaves the links out" do
    expect(rendered_component).to have_no_link("Open work package")
  end

  context "when the work package is already assigned to the user" do
    let(:assignee) { user }

    it "does not offer to assign it" do
      expect(rendered_component).to have_no_link("Assign work package to me")
    end
  end

  context "when the user may not change the assignee" do
    let(:permissions) { %i[view_project view_work_packages work_package_assigned log_own_time] }

    it "does not offer to assign it" do
      expect(rendered_component).to have_no_link("Assign work package to me")
      expect(rendered_component).to have_link("Log time from allocation")
    end
  end

  context "when the user may not be an assignee" do
    let(:permissions) { %i[view_project view_work_packages edit_work_packages log_own_time] }

    it "does not offer to assign it" do
      expect(rendered_component).to have_no_link("Assign work package to me")
    end
  end

  context "with navigation" do
    let(:navigation) { true }

    it "links to the work package and its project" do
      expect(rendered_component).to have_link("Open work package", href: "/work_packages/#{work_package.id}")
      expect(rendered_component).to have_link("Open project", href: "/projects/#{project.identifier}")
    end
  end

  context "when rendering the items only" do
    subject(:rendered_component) do
      render_inline(described_class.new(allocation:, navigation: true, list_only: true))
    end

    it "renders the list of the menu without a menu around it" do
      expect(rendered_component).to have_css("ul[role='menu']")
      expect(rendered_component).to have_no_css("action-menu")
      expect(rendered_component).to have_link("Open work package")
      expect(rendered_component).to have_link("Log time from allocation")
    end
  end

  context "when the work package is not visible" do
    let(:visible) { false }
    let(:navigation) { true }

    it "renders no menu" do
      expect(rendered_component.to_html).to be_blank
    end
  end
end
