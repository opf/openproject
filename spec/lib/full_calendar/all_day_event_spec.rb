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

RSpec.describe FullCalendar::AllDayEvent do
  it "is an all-day event spanning the inclusive range with an exclusive end" do
    json = described_class.new(range: Date.new(2026, 7, 1)..Date.new(2026, 7, 3), resource_id: 7).as_json

    expect(json).to include("allDay" => true, "start" => "2026-07-01", "end" => "2026-07-04", "resourceId" => "7")
  end

  it "renders a single day with the end on the next day" do
    json = described_class.new(range: Date.new(2026, 7, 1)..Date.new(2026, 7, 1)).as_json

    expect(json).to include("start" => "2026-07-01", "end" => "2026-07-02")
  end
end
