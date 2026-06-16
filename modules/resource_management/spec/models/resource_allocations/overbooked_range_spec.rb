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

RSpec.describe ResourceAllocations::OverbookedRange do
  subject(:range) do
    described_class.new(start_date: Date.new(2026, 1, 5), end_date: Date.new(2026, 1, 9),
                        work_package_ids: [1, 2], over_by_minutes: 90)
  end

  it "defaults work_package_ids to an empty array" do
    expect(described_class.new.work_package_ids).to eq([])
  end

  describe "#covers?" do
    it "is true for the boundaries and days inside the range" do
      expect(range.covers?(Date.new(2026, 1, 5))).to be true
      expect(range.covers?(Date.new(2026, 1, 7))).to be true
      expect(range.covers?(Date.new(2026, 1, 9))).to be true
    end

    it "is false for days outside the range" do
      expect(range.covers?(Date.new(2026, 1, 4))).to be false
      expect(range.covers?(Date.new(2026, 1, 10))).to be false
    end
  end
end
