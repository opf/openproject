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

RSpec.describe OpPrimer::QuickFilter::SegmentedControlComponent, type: :component do
  include QuickFilterHelpers

  let(:project) { build_stubbed(:project) }
  let(:query) { build_meeting_query }
  let(:orders) { nil }

  subject(:component) do
    described_class.new(
      name: "Test filter",
      query:,
      filter_key: :time,
      path_args: [project, :meetings],
      orders:
    )
  end

  context "when rendering with items" do
    before do
      render_inline(component) do |c|
        c.with_item(label: "Upcoming", value: "future")
        c.with_item(label: "Past", value: "past")
      end
    end

    it "renders all items" do
      expect(page).to have_text("Upcoming")
      expect(page).to have_text("Past")
    end

    it "renders a segmented control" do
      expect(page).to have_css("segmented-control [aria-label='Test filter']")
    end
  end

  context "when no items are given" do
    before do
      render_inline(component)
    end

    it "does not render" do
      expect(page).to have_no_css("segmented-control [aria-label='Test filter']")
    end
  end

  context "when an item matches the active filter value" do
    let(:query) { build_meeting_query.where("time", "=", ["future"]) }

    before do
      render_inline(component) do |c|
        c.with_item(label: "Upcoming", value: "future")
        c.with_item(label: "Past", value: "past")
      end
    end

    it "marks the matching item as selected" do
      expect(page).to have_css("[aria-current='true']", text: "Upcoming")
    end

    it "does not mark the other item as selected" do
      expect(page).to have_no_css("[aria-current='true']", text: "Past")
    end
  end

  context "when no filter is active" do
    before do
      render_inline(component) do |c|
        c.with_item(label: "All", value: nil)
        c.with_item(label: "Upcoming", value: "future")
        c.with_item(label: "Past", value: "past")
      end
    end

    it "marks the nil value item as selected" do
      expect(page).to have_css("[aria-current='true']", text: "All")
    end
  end

  context "when other filters are active" do
    let(:query) { build_meeting_query.where("time", "=", ["future"]) }

    subject(:component) do
      described_class.new(
        name: "Type filter",
        query:,
        filter_key: :type,
        path_args: [project, :meetings]
      )
    end

    before do
      render_inline(component) do |c|
        c.with_item(label: "All", value: nil)
        c.with_item(label: "One-time", value: "f")
        c.with_item(label: "Recurring", value: "t")
      end
    end

    it "excludes the target filter when value is nil, leaving others unchanged" do
      filter_keys = filters_from_link(page.find("a", text: "All")).map { |f| f.keys.first }

      expect(filter_keys).to include("time")
      expect(filter_keys).not_to include("type")
    end
  end

  context "with order overrides" do
    let(:orders) { { "future" => { start_time: :asc }, "past" => { start_time: :desc } } }

    before do
      render_inline(component) do |c|
        c.with_item(label: "Upcoming", value: "future")
        c.with_item(label: "Past", value: "past")
      end
    end

    it "uses the override sort for the matching value" do
      expect(sort_from_link(page.find("a", text: "Past"))).to eq([["start_time", "desc"]])
    end
  end
end
