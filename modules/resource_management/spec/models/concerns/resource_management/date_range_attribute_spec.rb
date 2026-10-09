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

RSpec.describe ResourceManagement::DateRangeAttribute do
  subject(:model) { ResourceAllocation.new }

  describe "#date_range=" do
    it "assigns both dates of a full range" do
      model.date_range = "2026-10-07 - 2026-10-09"

      expect(model.start_date).to eq(Date.new(2026, 10, 7))
      expect(model.end_date).to eq(Date.new(2026, 10, 9))
    end

    it "treats a single date without separator as a one-day range" do
      model.date_range = "2026-10-07"

      expect(model.start_date).to eq(Date.new(2026, 10, 7))
      expect(model.end_date).to eq(Date.new(2026, 10, 7))
    end

    it "assigns only the start date of a range open at the end" do
      model.date_range = "2026-10-07 - "

      expect(model.start_date).to eq(Date.new(2026, 10, 7))
      expect(model.end_date).to be_nil
    end

    it "assigns only the end date of a range open at the start" do
      model.date_range = " - 2026-10-07"

      expect(model.start_date).to be_nil
      expect(model.end_date).to eq(Date.new(2026, 10, 7))
    end

    it "clears both dates for a blank value" do
      model.start_date = Date.new(2026, 10, 7)
      model.end_date = Date.new(2026, 10, 9)

      model.date_range = ""

      expect(model.start_date).to be_nil
      expect(model.end_date).to be_nil
    end
  end

  describe "#date_range" do
    it "round-trips a one-day range" do
      model.date_range = "2026-10-07"

      expect(model.date_range).to eq("2026-10-07 - 2026-10-07")
    end
  end
end
