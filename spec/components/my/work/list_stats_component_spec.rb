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

require "rails_helper"

RSpec.describe My::Work::ListStatsComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:date) { Date.civil(2022, 5, 4) }
  let(:mode) { :day }
  let(:time_entries) { [] }
  let(:allocations) { nil }

  current_user { create(:user) }

  subject(:rendered_component) do
    render_component(time_entries:, allocations:, date:, mode:)
  end

  def allocated_on(day, minutes:)
    work_package = build_stubbed(:work_package)
    allocation = build_stubbed(:resource_allocation, entity: work_package)
    entry = ResourceAllocations::ScheduledEntry.new(allocation:, work_package:, allocated_on: day, minutes:)

    instance_double(ResourceAllocations::AllocatedTimeFor, items: [entry], visible?: true)
  end

  def stats
    rendered_component.text.squish
  end

  shared_examples_for "applying an ID" do
    it "applies an ID" do
      expect(rendered_component).to have_element id: "time-entries-list-stats-2022-05-04"
    end
  end

  context "with no time entries" do
    include_examples "applying an ID"

    it "renders no logged time" do
      expect(rendered_component).to have_css(".octicon-clock")
      expect(stats).to eq "0h"
    end
  end

  context "with time entries" do
    let(:time_entries) { build_list(:time_entry, 2, hours: 1.325) }

    include_examples "applying an ID"

    it "renders the logged time" do
      expect(stats).to eq "2h 39m"
    end
  end

  context "when the user works that day" do
    let(:time_entries) { build_list(:time_entry, 1, hours: 3) }

    before do
      create(:user_working_hours, user: current_user, valid_from: Date.civil(2022, 1, 1))
    end

    it "renders how much of the working hours is covered" do
      expect(stats).to eq "3h - 3h/8h"
      expect(rendered_component).to have_primer_text "- 3h/8h", color: "muted"
    end

    context "with allocated time" do
      let(:allocations) { allocated_on(date, minutes: 240) }

      it "renders the logged and the allocated time" do
        expect(rendered_component).to have_css(".octicon-op-person-assigned")
        expect(stats).to eq "3h 4h - 7h/8h"
      end
    end

    context "with only allocated time" do
      let(:time_entries) { [] }
      let(:allocations) { allocated_on(date, minutes: 240) }

      it "leaves the logged time out" do
        expect(rendered_component).to have_no_css(".octicon-clock")
        expect(stats).to eq "4h - 4h/8h"
      end
    end

    context "with more than the working hours covered" do
      let(:allocations) { allocated_on(date, minutes: 360) }

      it "highlights the coverage" do
        expect(rendered_component).to have_primer_text "- 9h/8h", color: "danger"
      end
    end

    context "when listing a month" do
      let(:mode) { :month }
      let(:date) { Date.civil(2022, 5, 2) }

      it "covers the working hours of the week" do
        expect(stats).to eq "3h - 3h/40h"
      end
    end

    context "with time allocated on another day" do
      let(:allocations) { allocated_on(date + 1.day, minutes: 240) }

      it "leaves it out" do
        expect(stats).to eq "3h - 3h/8h"
      end
    end
  end
end
