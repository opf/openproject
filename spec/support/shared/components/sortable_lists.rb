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

RSpec.shared_examples "a sortable-lists root" do |wrapper_id:, move_url_template:|
  it "wires ##{wrapper_id} as the sortable-lists root" do
    expect(rendered_component).to have_css("##{wrapper_id}") do |root|
      expect(root["data-controller"]).to eq("sortable-lists")
      expect(root["data-sortable-lists-move-url-template-value"]).to eq(move_url_template)
      expect(root["data-sortable-lists-sortable-lists--list-outlet"])
        .to eq("##{wrapper_id} [data-controller~='sortable-lists--list']")
      expect(root["data-sortable-lists-sortable-lists--item-outlet"])
        .to eq("##{wrapper_id} [data-controller~='sortable-lists--item']")
    end
  end
end

RSpec.shared_examples "a sortable-lists list" do |list_type:, name:|
  it "wires a single list of type #{list_type}" do
    expect(rendered_component).to have_css("[data-controller~='sortable-lists--list']", count: 1) do |list|
      expect(list["data-sortable-lists--list-type-value"]).to eq(list_type)
      expect(list["data-sortable-lists--list-accepted-type-value"]).to eq(list_type)
      expect(list["data-sortable-lists--list-name-value"]).to eq(name)
      expect(list["data-sortable-lists--list-rows-container-element"]).to be_nil
    end
  end
end

# Primer's BorderBox renders its rows into a direct `ul` child, which is the
# list controller's default rows container.
RSpec.shared_examples "a Border Box sortable list" do |row_count:|
  it "keeps #{row_count} rows in the list controller's default rows container" do
    expect(rendered_component)
      .to have_css("[data-controller~='sortable-lists--list'] > ul.Box-list > li.Box-row", count: row_count)
  end
end

# Consumers define `sortable_records` with a `let` in the inclusion block.
RSpec.shared_examples "sortable-lists items" do |list_type:|
  it "wires every row as a sortable item of type #{list_type}" do
    sortable_records.each do |record|
      expect(rendered_component)
        .to have_css("li.Box-row[data-sortable-lists--item-id-value='#{record.id}']") do |row|
        expect(row["data-controller"]).to eq("sortable-lists--item")
        expect(row["data-sortable-lists--item-type-value"]).to eq(list_type)
        expect(row["data-sortable-lists--item-label-value"]).to eq(record.name)
        expect(row).to have_css(".DragHandle[data-sortable-lists--item-target~='handle']", visible: :all)
      end
    end
  end
end

RSpec.shared_examples "no legacy drag-and-drop wiring" do
  it "no longer wires the generic drag-and-drop controller", :aggregate_failures do
    expect(rendered_component).to have_no_css("[data-controller~='generic-drag-and-drop']")
    expect(rendered_component).to have_no_css("[data-generic-drag-and-drop-target]")
    expect(rendered_component).to have_no_css("[data-drop-url]")
  end
end
