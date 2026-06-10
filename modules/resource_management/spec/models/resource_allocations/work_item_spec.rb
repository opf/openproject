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

RSpec.describe ResourceAllocations::WorkItem do
  it "casts attributes to their declared types" do
    item = described_class.new(id: 1, start_date: "2026-01-05", end_date: "2026-01-09", minutes: "600")

    expect(item.start_date).to eq(Date.new(2026, 1, 5))
    expect(item.end_date).to eq(Date.new(2026, 1, 9))
    expect(item.minutes).to eq(600)
  end

  describe ".from_allocation" do
    let(:allocation) do
      create(:resource_allocation,
             start_date: Date.new(2026, 1, 5),
             end_date: Date.new(2026, 1, 9),
             allocated_time: 600)
    end

    it "maps the allocation's window, minutes and work package" do
      item = described_class.from_allocation(allocation)

      expect(item).to have_attributes(
        id: allocation.id,
        start_date: Date.new(2026, 1, 5),
        end_date: Date.new(2026, 1, 9),
        minutes: 600,
        work_package_id: allocation.entity_id
      )
    end
  end
end
