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

RSpec.describe FullCalendar::Event do
  it "serializes a timed event from its datetimes" do
    json = described_class.new(
      id: 42, starts_at: Time.utc(2026, 7, 1, 9), ends_at: Time.utc(2026, 7, 1, 17), title: "Standup"
    ).as_json

    expect(json).to include("id" => "42", "start" => "2026-07-01T09:00:00.000Z", "end" => "2026-07-01T17:00:00.000Z",
                            "title" => "Standup", "allDay" => false)
  end

  it "serializes an all-day event from an inclusive date range, pushing the end to the exclusive boundary" do
    json = described_class.new(
      all_day: true, date_range: Date.new(2026, 7, 1)..Date.new(2026, 7, 3)
    ).as_json

    expect(json).to include("start" => "2026-07-01", "end" => "2026-07-04", "allDay" => true)
  end

  it "carries the resource id, display and extended props" do
    json = described_class.new(
      all_day: true, date_range: Date.new(2026, 7, 1)..Date.new(2026, 7, 1),
      resource_id: 7, display: "background", extended_props: { html: "bar" }
    ).as_json

    expect(json).to include("resourceId" => "7", "display" => "background", "extendedProps" => { "html" => "bar" })
  end

  it "omits the resource-timeline keys when they are not set" do
    json = described_class.new(starts_at: Time.utc(2026, 7, 1), ends_at: Time.utc(2026, 7, 1)).as_json

    expect(json).not_to have_key("resourceId")
    expect(json).not_to have_key("display")
    expect(json).not_to have_key("extendedProps")
  end

  it "accepts serialization options so `render json:` can pass them" do
    event = described_class.new(id: 1, starts_at: Time.utc(2026, 7, 1), ends_at: Time.utc(2026, 7, 1))

    expect { event.as_json(except: :whatever) }.not_to raise_error
  end
end
