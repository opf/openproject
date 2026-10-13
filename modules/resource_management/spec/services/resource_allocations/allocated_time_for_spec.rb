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

require "spec_helper"

RSpec.describe ResourceAllocations::AllocatedTimeFor, with_ee: %i[resource_management] do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:monday) { Date.new(2026, 1, 5) }
  shared_let(:tuesday) { Date.new(2026, 1, 6) }
  shared_let(:wednesday) { Date.new(2026, 1, 7) }
  shared_let(:friday) { Date.new(2026, 1, 9) }

  let(:dates) { monday..friday }

  subject(:allocations) { described_class.new(user:, dates:) }

  before do
    create(:user_working_hours, user:, valid_from: Date.new(2025, 1, 1))
  end

  def allocate(minutes, start_date: monday, end_date: friday, entity: create(:work_package, project:))
    create(:resource_allocation, principal: user, entity:, allocated_time: minutes, start_date:, end_date:)
  end

  def scheduled
    allocations.items.map { |entry| [entry.allocation.id, entry.allocated_on, entry.minutes] }
  end

  describe "#items" do
    it "places the allocations the way the fit check does" do
      urgent = allocate(960, end_date: tuesday)
      relaxed = allocate(480)

      expect(scheduled).to contain_exactly(
        [urgent.id, monday, 480],
        [urgent.id, tuesday, 480],
        [relaxed.id, wednesday, 480]
      )
    end

    context "when only part of the schedule is displayed" do
      let(:dates) { [wednesday] }

      it "keeps the placement computed across all allocations" do
        allocate(960, end_date: tuesday)
        relaxed = allocate(480)

        expect(scheduled).to contain_exactly([relaxed.id, wednesday, 480])
      end
    end

    context "without the resource management enterprise feature", with_ee: false do
      it "is empty" do
        allocate(480)

        expect(allocations.items).to be_empty
      end
    end
  end

  describe "#events" do
    subject(:events) { allocations.events.map(&:as_json) }

    it "returns one event per allocation and day" do
      urgent = allocate(960, end_date: tuesday)

      expect(events.map { |event| event.values_at("allocationId", "start", "hours") }).to contain_exactly(
        [urgent.id, monday.as_json, 8.0],
        [urgent.id, tuesday.as_json, 8.0]
      )
    end

    context "when the work package is not visible to the user" do
      it "shows a placeholder instead of the work package" do
        allocate(480, end_date: monday, entity: create(:work_package))

        expect(events.sole).to include("title" => I18n.t("resource_management.my_work.hidden_work_package"))
        expect(events.sole).not_to have_key("workPackageSubject")
      end
    end
  end
end
