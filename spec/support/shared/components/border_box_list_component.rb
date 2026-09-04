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

# Shared expectations for lists rendered through
# OpenProject::Common::BorderBoxListComponent.
#
# Asserts the heading is a real heading element rendered inside the
# +.Box-header+, not merely text that happens to appear somewhere.
RSpec.shared_examples_for "rendering Border Box List heading" do |text:, level: nil|
  it "renders Border Box List heading '#{text}'" do
    expect(rendered_component).to have_css(".Box-header") do |header|
      expect(header).to have_heading(text, **{ level: }.compact)
    end
  end
end

# Shared expectations for an itemless Border Box List: the component renders
# a single Blank Slate row in place of the list items.
RSpec.shared_examples_for "rendering an empty Border Box List" do |heading:, icon: nil, header: true|
  it_behaves_like("rendering Box", row_count: 0, header:)
  it_behaves_like("rendering Blank Slate", heading:, icon:)
end

# Shared expectations for lists rendered through
# OpenProject::Common::BorderBoxListComponent with generic drag-and-drop
# reordering.
#
# Including contexts must pass +drag_type:+ and define the following:
#
# - +draggable_records+: ordered records expected to render as rows.
# - +drop_url_for(record)+: the value each row's +data-drop-url+ ends with.
# - +draggable_id_for(record)+: optional value for +data-draggable-id+.
#   Defaults to +record.id+.
RSpec.shared_examples_for "a reorderable Border Box List" do |drag_type:|
  it "renders a drag-and-drop enabled Border Box List container" do
    expect(rendered_component)
      .to have_css(".Box.op-border-box-list[data-generic-drag-and-drop-target='container']") do |box|
        expect(box["data-target-container-accessor"]).to eq(":scope > ul")
        expect(box["data-target-allowed-drag-type"]).to eq(drag_type)
      end
  end

  it "renders the expected number of draggable rows" do
    expect(rendered_component)
      .to have_css(".Box-row[data-draggable-type='#{drag_type}']", count: draggable_records.size)
  end

  it "renders each record as a draggable row pointing at its drop URL", :aggregate_failures do
    draggable_records.each do |record|
      draggable_id = respond_to?(:draggable_id_for) ? draggable_id_for(record) : record.id
      selector = ".Box-row[data-draggable-type='#{drag_type}'][data-draggable-id='#{draggable_id}']"

      expect(rendered_component).to have_css(selector) do |row|
        expect(row["data-drop-url"]).to end_with(drop_url_for(record))
      end
    end
  end
end

# Asserts the declarative sortable wiring of a Border Box List consumer:
# the list role on the box root, exactly one item controller per row, and
# no stray sortable-lists attributes outside the declared roles. Pages
# where the box itself is also a draggable item wire that through the
# Border Box List collection instead (see "a sortable Border Box List
# collection" below) — BorderBoxListComponent raises if `sortable_list:`
# and `sortable_item:` are combined, since the list and item Stimulus
# controllers cannot yet share one element (see
# BorderBoxListComponent#assert_no_combined_sortable_roles!). `item_type:`
# is separate from `list_type:` because a list may accept a different type
# than it is (a sprint list accepting work packages).
RSpec.shared_examples_for "a sortable Border Box List" do |list_type:, item_type:, item_count:|
  it "wires the list role on the box root" do
    expect(rendered_component).to have_css(
      ".op-border-box-list[data-controller~='sortable-lists--list'][data-sortable-lists--list-type-value='#{list_type}']",
      count: 1
    )
    expect(rendered_component).to have_no_css("ul[data-controller~='sortable-lists--list']")
  end

  it "wires exactly one item controller per row" do
    expect(rendered_component).to have_css(
      "ul > li[data-controller~='sortable-lists--item'][data-sortable-lists--item-type-value='#{item_type}']",
      count: item_count
    )
  end

  it_behaves_like "having no stray sortable-lists attributes"
end

# Ownership schema for sortable-lists Stimulus wiring: an element either
# HOSTS exactly one sortable-lists controller (the root `sortable-lists`, or
# one of `sortable-lists--list`/`--item`/`--scrollable`), or is TARGET-ONLY,
# carrying nothing among its `data-sortable-lists*` attributes but
# `data-sortable-lists--item-target`. The per-role assertions above only
# check that a given role's attributes ARE present somewhere; they cannot
# see wiring that drifted onto a shared element (e.g. a list and an item
# controller landing on the same node), which is what this guards against.
#
# Attribute-name prefixes are not CSS-selectable, so this inspects the
# rendered fragment's own attribute nodes directly rather than composing a
# selector. Including contexts must define +rendered_component+ as the raw
# object `render_inline` (or `with_request_url { render_inline(...) }`)
# returns — a Nokogiri fragment responding to `#css` directly, not a
# Capybara node requiring `#native`.
RSpec.shared_examples_for "having no stray sortable-lists attributes" do
  it "has no stray sortable-lists attributes outside the declared roles" do
    hosts = rendered_component.css("*").select do |el|
      el.attribute_nodes.any? do |attribute|
        attribute.name.start_with?("data-sortable-lists") ||
          (attribute.name == "data-controller" && attribute.value.include?("sortable-lists"))
      end
    end

    hosts.each do |el|
      controllers = (el["data-controller"] || "").split
      sortable_controllers = controllers.grep(/\Asortable-lists/)

      if sortable_controllers.empty?
        expect(el.attribute_nodes.map(&:name)).to(
          all(satisfy { |name| !name.start_with?("data-sortable-lists") || name == "data-sortable-lists--item-target" }),
          "target-only <#{el.name}> carries non-target sortable attributes: #{el.attribute_nodes.map(&:name)}"
        )
      else
        expect(sortable_controllers.size).to(
          eq(1),
          "<#{el.name}> hosts multiple sortable-lists controllers: #{sortable_controllers}"
        )
      end
    end
  end
end

# Shared expectations for a Border Box List collection (a
# BorderBoxListCollectionComponent consumer): the page-level sortable-lists
# root wired onto the collection wrapper, the list role wired onto an inner
# descendant of the wrapper rather than the wrapper itself (see
# BorderBoxListCollectionComponent#list_container_arguments for why — a
# root's outlet selectors are plain CSS descendant combinators, which can
# never match the wrapper they are scoped from), exactly one item
# controller per row, and no stray sortable-lists attributes outside the
# declared roles.
RSpec.shared_examples_for "a sortable Border Box List collection" do |list_type:, item_type:, item_count:, wrapper_id:|
  it "wires the collection wrapper with the sortable-lists root" do
    expect(rendered_component).to have_css("##{wrapper_id}") do |wrapper|
      expect(wrapper["data-controller"]).to include("sortable-lists")
    end
  end

  it "wires the list role on an inner descendant of the wrapper, not the wrapper itself" do
    expect(rendered_component).to have_no_css("##{wrapper_id}[data-controller~='sortable-lists--list']")
    expect(rendered_component).to have_css("##{wrapper_id} [data-controller~='sortable-lists--list']") do |list|
      expect(list["data-sortable-lists--list-type-value"]).to eq(list_type)
    end
  end

  it "wires exactly one item controller per row" do
    expect(rendered_component).to have_css(
      "[data-controller~='sortable-lists--item'][data-sortable-lists--item-type-value='#{item_type}']",
      count: item_count
    )
  end

  it_behaves_like "having no stray sortable-lists attributes"
end
