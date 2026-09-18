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

RSpec.describe Documents::Admin::DocumentTypes::IndexComponent, type: :component do
  let!(:first_type) { create(:document_type, name: "Note") }
  let!(:second_type) { create(:document_type, name: "Report") }

  subject(:rendered_component) do
    with_request_url("/admin/settings/document_types") do
      render_inline(described_class.new(enumerations: DocumentType.reorder(:position)))
    end
  end

  it "wires the wrapper as the sortable-lists root", :aggregate_failures do
    root = rendered_component.at_css("#documents-admin-document-types-index-component")

    expect(root["data-controller"]).to eq("sortable-lists")
    expect(root["data-sortable-lists-move-url-template-value"])
      .to eq("/admin/settings/document_types/{id}/move")
  end

  it "wires the border box as the sortable list", :aggregate_failures do
    list = rendered_component.at_css("[data-controller~='sortable-lists--list']")

    expect(list["data-sortable-lists--list-type-value"]).to eq("document_type")
    expect(list["data-sortable-lists--list-accepted-type-value"]).to eq("document_type")
    expect(list["data-sortable-lists--list-name-value"])
      .to eq(DocumentType.model_name.human(count: :other))
  end

  # border_box_container renders a Primer BorderBox, whose rows land in a
  # direct `ul` child, which is the list controller's default rows container.
  it "keeps the rows in the list controller's default rows container" do
    expect(rendered_component)
      .to have_css("[data-controller~='sortable-lists--list'] > ul.Box-list > li.Box-row", count: 2)
  end

  it "does not override the rows container selector" do
    expect(rendered_component).to have_no_css("[data-sortable-lists--list-rows-container-element]")
  end

  it "wires every row as a sortable item", :aggregate_failures do
    [first_type, second_type].each do |document_type|
      row = rendered_component.at_css(".Box-row[data-sortable-lists--item-id-value='#{document_type.id}']")

      expect(row["data-controller"]).to eq("sortable-lists--item")
      expect(row["data-sortable-lists--item-type-value"]).to eq("document_type")
      expect(row["data-sortable-lists--item-label-value"]).to eq(document_type.name)
    end
  end

  it "targets each drag handle for the item controller" do
    expect(rendered_component)
      .to have_css(".DragHandle[data-sortable-lists--item-target~='handle']", count: 2, visible: :all)
  end

  it "keeps the two-column grid" do
    expect(rendered_component).to have_css(".op-documents-types-list--header", visible: :all)
    expect(rendered_component).to have_css(".op-documents-types-list--item", count: 2, visible: :all)
  end

  it "no longer wires the legacy drag-and-drop controller", :aggregate_failures do
    expect(rendered_component).to have_no_css("[data-controller~='generic-drag-and-drop']")
    expect(rendered_component).to have_no_css("[data-drop-url]")
  end
end
