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

RSpec.describe OpenProject::Common::BorderBoxListCollectionComponent, type: :component do
  subject(:rendered_component) { page }

  def render_collection(**args, &)
    render_inline(described_class.new(container: "sections-collection", **args), &)
  end

  it "renders a stable identified wrapper even when empty" do
    render_collection(sortable_list: { type: "section" })

    expect(rendered_component).to have_element("div", id: "sections-collection")
  end

  it "derives a root scoped to its own wrapper for root: true" do
    render_collection(
      sortable_list: { type: "section" },
      root: true,
      move_urls: ->(id) { { section: "/sections/#{id}/drop" } }
    )

    expect(rendered_component).to have_element("div", id: "sections-collection") do |wrapper|
      expect(wrapper["data-controller"]).to include("sortable-lists")
      expect(wrapper["data-sortable-lists-sortable-lists--item-outlet"])
        .to eq("#sections-collection [data-controller~='sortable-lists--item']")
    end
  end

  it "wires the inner list container — never the wrapper itself — as the sortable-lists list" do
    render_collection(sortable_list: { type: "section" })

    expect(rendered_component).to have_element("div", id: "sections-collection") do |wrapper|
      expect(wrapper["data-controller"].to_s.split).not_to include("sortable-lists--list")
    end

    # The exact shape of a root's own outlet selector
    # (`##{wrapper_id} [data-controller~='sortable-lists--list']`): a plain
    # CSS descendant combinator, which by the DOM spec can never match the
    # wrapper element it is scoped from. Asserting the list role resolves
    # through that selector — not just "somewhere in the markup" — proves it
    # sits on a genuine descendant the root can actually see.
    expect(rendered_component).to have_css("#sections-collection [data-controller~='sortable-lists--list']") do |list|
      expect(list["data-sortable-lists--list-type-value"]).to eq("section")
      expect(list["data-sortable-lists--list-accepted-type-value"]).to eq("section")
    end
  end

  it "raises when root: true is given without move_urls" do
    expect { render_collection(sortable_list: { type: "section" }, root: true) }
      .to raise_error(ArgumentError, /move_urls/)
  end

  it "raises for an explicit Root whose scope does not match the wrapper" do
    mismatched = OpPrimer::SortableLists::Root.new(scope_id: "elsewhere", move_url: ->(id) { "/m/#{id}" })

    expect { render_collection(root: mismatched) }.to raise_error(ArgumentError, /scope_id/)
  end

  it "accepts an explicit Root whose scope matches the wrapper" do
    matching = OpPrimer::SortableLists::Root.new(scope_id: "sections-collection", move_url: ->(id) { "/m/#{id}" })

    render_collection(sortable_list: { type: "section" }, root: matching)

    expect(rendered_component).to have_element("div", id: "sections-collection") do |wrapper|
      expect(wrapper["data-controller"]).to include("sortable-lists")
    end
  end

  it "wires exactly one item controller per row, on the row element" do
    render_collection(sortable_list: { type: "section" }) do |collection|
      collection.with_item_row(sortable: { id: 7, label: "Marketing" }) { "box one" }
      collection.with_item_row(sortable: { id: 9, label: "PR" }) { "box two" }
    end

    expect(rendered_component).to have_css("[data-controller~='sortable-lists--item']", count: 2)
    expect(rendered_component).to have_element("div", "data-sortable-lists--item-id-value": "7") do |row|
      expect(row["data-sortable-lists--item-type-value"]).to eq("section")
      expect(row.text).to include("box one")
    end
  end

  it "defaults a row's sortable type from the collection's sortable_list accepted_type" do
    render_collection(sortable_list: { type: "section", accepted_type: "custom_field" }) do |collection|
      collection.with_item_row(sortable: { id: 3, label: "Priority" }) { "row content" }
    end

    expect(rendered_component).to have_element("div", "data-sortable-lists--item-id-value": "3") do |row|
      expect(row["data-sortable-lists--item-type-value"]).to eq("custom_field")
    end
  end

  it "raises when a row's sortable is given without the component's sortable_list" do
    expect do
      render_collection do |collection|
        collection.with_item_row(sortable: { id: 3, label: "Priority" }) { "row content" }
      end
    end.to raise_error(ArgumentError, /sortable_list/)
  end

  it "renders free-form row content without imposing BorderBox row semantics" do
    render_collection do |collection|
      collection.with_item_row { "<span>plain content</span>".html_safe }
    end

    expect(rendered_component).to have_css("span", text: "plain content")
  end
end
