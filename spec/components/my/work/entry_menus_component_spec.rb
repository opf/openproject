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

RSpec.describe My::Work::EntryMenusComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking costs]) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:user) do
    create(:user, member_with_permissions: { project => %i[view_project view_work_packages log_own_time edit_own_time_entries] })
  end
  let(:date) { Date.new(2026, 10, 5) }
  let(:time_entries) { [create(:time_entry, user:, entity: work_package, spent_on: date, hours: 2)] }
  let(:allocation_minutes) { 360 }
  let(:allocation_event) do
    allocation = build_stubbed(:resource_allocation, entity: work_package, principal: user)
    entry = ResourceAllocations::ScheduledEntry.new(allocation:, work_package:, allocated_on: date,
                                                    minutes: allocation_minutes)

    FullCalendar::ResourceAllocationEvent.from_scheduled_entry(entry, visible: true)
  end

  current_user { user }

  subject(:rendered_component) do
    render_inline(described_class.new(time_entries:, allocations: [allocation_event]))
  end

  it "renders the menu of each time entry under the id of its calendar event" do
    expect(rendered_component).to have_css("[data-my-work-menu-for='#{time_entries.first.id}'] action-menu")
  end

  it "renders the menu of each allocation under the id of its calendar event" do
    expect(rendered_component).to have_css("[data-my-work-menu-for='#{allocation_event.id}'] action-menu")
  end

  it "keeps the menus out of sight without hiding them" do
    expect(rendered_component).to have_css("[data-my-work-menus].sr-only")
    expect(rendered_component).to have_no_css("[data-my-work-menus][hidden]")
  end

  it "offers the links to the work package and project" do
    expect(rendered_component).to have_link("Open work package", visible: :all, count: 2)
  end

  context "when the allocation was logged in full" do
    let(:allocation_minutes) { 120 }

    it "renders no menu for it" do
      expect(rendered_component).to have_no_css("[data-my-work-menu-for='#{allocation_event.id}']")
    end
  end
end
