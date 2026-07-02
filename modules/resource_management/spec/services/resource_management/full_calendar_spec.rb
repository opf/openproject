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

RSpec.describe ResourceManagement::FullCalendar do
  describe ".range_from_params" do
    it "converts the exclusive-end window into an inclusive range" do
      params = { start: "2026-07-01", end: "2026-07-08" }

      expect(described_class.range_from_params(params))
        .to eq(Date.new(2026, 7, 1)..Date.new(2026, 7, 7))
    end

    it "returns nil when the start param is absent" do
      expect(described_class.range_from_params({ end: "2026-07-08" })).to be_nil
    end

    it "returns nil when the end param is absent" do
      expect(described_class.range_from_params({ start: "2026-07-01" })).to be_nil
    end
  end

  describe ".background" do
    it "emits a background span with the end pushed to FullCalendar's exclusive boundary" do
      range = Date.new(2026, 7, 1)..Date.new(2026, 7, 3)

      expect(described_class.background(resource_id: 42, range:, class_names: ["op-rm-timeline-active"]))
        .to eq(
          resourceId: 42,
          start: "2026-07-01",
          end: "2026-07-04",
          display: "background",
          classNames: ["op-rm-timeline-active"]
        )
    end
  end

  describe ".event" do
    it "emits a timed event with id, extended props and class names" do
      range = Date.new(2026, 7, 1)..Date.new(2026, 7, 3)

      expect(
        described_class.event(resource_id: 42, range:, id: 7,
                              extended_props: { html: "bar" }, class_names: ["op-rm-timeline-non-working"])
      ).to eq(
        id: 7,
        resourceId: 42,
        start: "2026-07-01",
        end: "2026-07-04",
        extendedProps: { html: "bar" },
        classNames: ["op-rm-timeline-non-working"]
      )
    end

    it "omits absent id, extended props and class names" do
      range = Date.new(2026, 7, 1)..Date.new(2026, 7, 1)

      expect(described_class.event(resource_id: 42, range:))
        .to eq(resourceId: 42, start: "2026-07-01", end: "2026-07-02")
    end
  end

  describe ".resource" do
    it "emits a resource row" do
      expect(described_class.resource(id: 7, title: "Alice", order: 0, extended_props: { html: "cell" }))
        .to eq(id: 7, title: "Alice", order: 0, extendedProps: { html: "cell" })
    end
  end
end
