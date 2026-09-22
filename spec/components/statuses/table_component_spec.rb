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

RSpec.describe Statuses::TableComponent, type: :component do
  subject(:rendered_component) do
    with_request_url("/statuses") do
      render_inline(described_class.new(rows: statuses, query:, page_args:))
    end
  end

  let(:page_args) { { page: 1, per_page: 20 } }
  let(:query) { Queries::Statuses::StatusQuery.new(user: User.current) }
  let(:statuses) { relation.page(page_args[:page]).per_page(page_args[:per_page]) }

  context "with statuses" do
    let!(:new_status) { create(:status, name: "New", is_default: true, default_done_ratio: 0) }
    let!(:closed_status) { create(:status, name: "Closed", is_closed: true, default_done_ratio: 100) }
    let(:relation) { Status.where(id: [new_status.id, closed_status.id]) }

    it_behaves_like "rendering Box", row_count: 2

    it "captions the columns", :aggregate_failures do
      expect(rendered_component).to have_css(".Box-header", text: "Name")
      expect(rendered_component).to have_css(".Box-header", text: "Closed")
      expect(rendered_component).to have_css(".Box-header", text: "Read-only")
    end

    it "renders a row per status", :aggregate_failures do
      expect(rendered_component).to have_css(".Box-row", text: "New")
      expect(rendered_component).to have_css(".Box-row", text: "Closed")
    end

    it "links each status to its edit page" do
      expect(rendered_component).to have_link("New", href: "/statuses/#{new_status.id}/edit")
    end

    context "in status-based progress mode", with_settings: { work_package_done_ratio: "status" } do
      it "gives % Complete a column of its own", :aggregate_failures do
        expect(rendered_component).to have_css(".Box-header", text: "% Complete")
        expect(rendered_component).to have_test_selector("done-ratio", text: "100%")
      end
    end

    context "in work-based progress mode", with_settings: { work_package_done_ratio: "field" } do
      it "drops the % Complete column, which has no effect in that mode", :aggregate_failures do
        expect(rendered_component).to have_no_css(".Box-header", text: "% Complete")
        expect(rendered_component).to have_no_test_selector("done-ratio")
      end
    end

    it "wires a sortable list accepting statuses" do
      expect(rendered_component).to have_css("#statuses-table[data-controller='sortable-lists sortable-lists--list']") do |box|
        expect(box["data-sortable-lists--list-type-value"]).to eq("status")
        expect(box["data-sortable-lists--list-accepted-type-value"]).to eq("status")
        expect(box["data-sortable-lists--list-name-value"]).to eq("Statuses")
        expect(box["data-sortable-lists--list-id-value"]).to be_nil
      end
    end

    it "scopes the sortable outlets and preserves pagination in the URL template" do
      expect(rendered_component).to have_css("#statuses-table") do |root|
        expect(root["data-sortable-lists-move-url-template-value"]).to eq("/statuses/{id}/move?page=1&per_page=20")
        expect(root["data-sortable-lists-sortable-lists--list-outlet"]).to eq("#statuses-table")
        expect(root["data-sortable-lists-sortable-lists--item-outlet"])
          .to eq("#statuses-table [data-controller~='sortable-lists--item']")
      end
    end

    # The drop indicator and the faded source are styled off this container, so the rows
    # have to sit inside it rather than anywhere under the box.
    it "points the list at the rows container the drag-and-drop styling keys on" do
      expect(rendered_component).to have_css("#statuses-table") do |root|
        expect(root["data-sortable-lists--list-rows-container-element"]).to eq(":scope > .op-border-box-table--rows")
      end

      expect(rendered_component).to have_css(".op-border-box-table--rows > .Box-row", count: 2)
    end

    it "renders each status as an identified sortable row", :aggregate_failures do
      [new_status, closed_status].each do |status|
        selector = ".Box-row[data-controller='sortable-lists--item'][data-sortable-lists--item-id-value='#{status.id}']"

        expect(rendered_component).to have_css(selector) do |row|
          expect(row["data-sortable-lists--item-type-value"]).to eq("status")
          expect(row["data-sortable-lists--item-label-value"]).to eq(status.name)
        end
      end

      expect(rendered_component).to have_no_css(".Box-header[data-controller='sortable-lists--item']")
      expect(rendered_component).to have_no_css("[data-controller='generic-drag-and-drop'], [data-draggable-id], [data-drop-url]")
    end

    # Without it the drag image is the browser's own snapshot instead of the lifted card.
    it "drags the whole row rather than the handle alone" do
      expect(rendered_component)
        .to have_css(".Box-row[data-sortable-lists--item-target='preview']", count: 2)
    end
  end

  describe "reordering across pages" do
    let!(:first) { create(:status, name: "First") }
    let!(:second) { create(:status, name: "Second") }
    let!(:third) { create(:status, name: "Third") }
    let(:relation) { Status.all }
    let(:page_args) { { page: 1, per_page: 2 } }

    it "keeps the downward moves on the last row of a page, which is not the last of the list" do
      row = "[data-test-selector='status-row-#{second.id}']"

      expect(rendered_component).to have_css("#{row} button", text: "Move down")
      expect(rendered_component).to have_css("#{row} button", text: "Move to bottom")
    end
  end

  context "when filtered" do
    let!(:new_status) { create(:status, name: "New") }
    let!(:task) { create(:type, name: "Task") }
    let(:relation) { Status.where(id: new_status.id) }
    let(:query) do
      Queries::Statuses::StatusQuery.new(user: User.current).tap { it.where("type", "=", [task.id.to_s]) }
    end

    it "offers no reordering, since positions are global and the list is a subset" do
      expect(rendered_component).to have_no_css("[data-controller*='sortable-lists']")
      expect(rendered_component).to have_no_css(".DragHandle")
      expect(rendered_component).to have_no_button("Move to top")
    end

    context "when the filter matches nothing" do
      let(:relation) { Status.none }

      it "says the filter came up empty rather than that no status exists" do
        expect(rendered_component).to have_text("No status matches the current filter.")
        expect(rendered_component).to have_no_text("There are currently no work package statuses.")
      end
    end
  end

  context "without statuses" do
    let(:relation) { Status.where(id: nil) }

    it "says no status exists yet" do
      expect(rendered_component).to have_text("There are currently no work package statuses.")
      expect(rendered_component).to have_no_css("[data-controller='sortable-lists--item']")
    end
  end
end
