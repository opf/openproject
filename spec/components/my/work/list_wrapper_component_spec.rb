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

RSpec.describe My::Work::ListWrapperComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:date) { Date.civil(2022, 5, 4) }
  let(:mode) { :month }

  subject(:rendered_component) do
    render_component(time_entries:, date:, mode:)
  end

  shared_examples_for "applying an ID" do
    it "applies an ID" do
      expect(rendered_component).to have_element id: "time-entries-list-2022-05-04"
    end
  end

  context "with no time entries" do
    let(:time_entries) { create_list(:time_entry, 0) }

    it_behaves_like "rendering Box", row_count: 1
  end

  context "with time entries" do
    let(:time_entries) { create_list(:time_entry, 2) }

    it_behaves_like "rendering Box", row_count: 2

    it "marks the entries as time entries" do
      expect(rendered_component).to have_css(".type .octicon-clock", count: 2)
      expect(rendered_component).to have_css(".type", text: "Time entry", count: 2)
    end
  end

  context "with allocations" do
    let(:mode) { :day }
    let(:work_package) { create(:work_package, subject: "Plan the conference") }
    let(:allocation) { build_stubbed(:resource_allocation, entity: work_package) }
    let(:visible) { true }
    let(:allocation_event) do
      entry = ResourceAllocations::ScheduledEntry.new(allocation:, work_package:, allocated_on: date, minutes: 360)
      FullCalendar::ResourceAllocationEvent.from_scheduled_entry(entry, visible:)
    end
    let(:time_entries) { [] }

    subject(:rendered_component) do
      render_component(time_entries:, allocations: [allocation_event], date:, mode:)
    end

    it_behaves_like "rendering Box", row_count: 1

    it "lists the allocation as a resource allocation" do
      expect(rendered_component).to have_css(".type .octicon-op-person-assigned")
      expect(rendered_component).to have_css(".type", text: "Resource Allocation")
      expect(rendered_component).to have_css(".hours", text: "6h")
      expect(rendered_component).to have_text("Plan the conference")
    end

    it "gives the allocation an empty actions cell to keep it aligned with the grid" do
      expect(rendered_component).to have_css(".op-border-box-grid__row-action[role=cell]")
    end

    context "when time was logged on the work package that day" do
      let(:time_entries) { [create(:time_entry, entity: work_package, spent_on: date, hours: 2)] }

      it "lists the time entry and what is left of the allocation" do
        expect(rendered_component).to have_css(".type", text: "Time entry")
        expect(rendered_component).to have_css(".hours", text: "4h")
      end
    end

    context "when the allocation was logged in full" do
      let(:time_entries) { [create(:time_entry, entity: work_package, spent_on: date, hours: 6)] }

      it "leaves the allocation out" do
        expect(rendered_component).to have_no_css(".type", text: "Resource Allocation")
      end
    end

    context "when the work package is not visible" do
      let(:visible) { false }

      it "does not reveal the work package" do
        expect(rendered_component).to have_text(I18n.t("resource_management.my_work.hidden_work_package"))
        expect(rendered_component).to have_no_text("Plan the conference")
      end
    end
  end
end
