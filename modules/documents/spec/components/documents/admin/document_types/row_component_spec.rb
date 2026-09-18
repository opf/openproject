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

RSpec.describe Documents::Admin::DocumentTypes::RowComponent, type: :component do
  subject(:rendered_component) do
    with_request_url("/admin/settings/document_types") do
      render_inline(described_class.new(row: document_type, table:))
    end
  end

  let!(:document_type) { create(:document_type, name: "Note") }
  let(:table) { Documents::Admin::DocumentTypes::TableComponent.new(rows: DocumentType.reorder(:position)) }
  let(:move_items) { rendered_component.css("li[data-sortable-lists--item-target~='moveItem']") }

  it "links the name to the edit page" do
    expect(rendered_component)
      .to have_link("Note", href: "/admin/settings/document_types/#{document_type.id}/edit")
  end

  it "shows how many documents use the type" do
    create_list(:document, 2, type: document_type)

    expect(rendered_component).to have_test_selector("documents-count", text: "2")
  end

  it "offers a drag handle the item controller owns" do
    expect(rendered_component).to have_css(".DragHandle[data-sortable-lists--item-target~='handle']")
  end

  it "identifies the row to the item controller and drags it whole", :aggregate_failures do
    row = described_class.new(row: document_type, table:)

    expect(row.row_css_id).to eq("document-type-#{document_type.id}")
    expect(row.row_data).to eq(
      test_selector: "document-type-row-#{document_type.id}",
      controller: "sortable-lists--item",
      sortable_lists__item_target: "preview",
      sortable_lists__item_id_value: document_type.id,
      sortable_lists__item_type_value: "document_type",
      sortable_lists__item_label_value: "Note"
    )
  end

  describe "labels beside the name" do
    context "when the document type is the default one" do
      let!(:document_type) { create(:document_type, name: "Note", is_default: true) }

      it "labels it as the default" do
        expect(rendered_component).to have_test_selector("label-is-default", text: I18n.t(:label_default))
      end
    end

    context "when the document type is inactive" do
      let!(:document_type) { create(:document_type, name: "Note", active: false) }

      it "labels it as inactive" do
        expect(rendered_component).to have_test_selector("label-inactive", text: I18n.t(:label_inactive))
      end
    end

    context "when the document type is active and not the default one" do
      it "carries neither label", :aggregate_failures do
        expect(rendered_component).to have_no_test_selector("label-is-default")
        expect(rendered_component).to have_no_test_selector("label-inactive")
      end
    end
  end

  describe "the action menu" do
    it "keeps the actions out of print, like the drag handle", :aggregate_failures do
      expect(rendered_component)
        .to have_css("[data-test-selector='op-document-types--action-menu'].hide-when-print", visible: :all)
      expect(rendered_component).to have_css(".DragHandle.hide-when-print", visible: :all)
    end

    it "sits behind a labelled show button", :aggregate_failures do
      expect(rendered_component).to have_test_selector("op-document-types--action-menu")

      show_button = rendered_component.at_css("[data-test-selector='op-document-types--action-menu'] button[aria-labelledby]")
      tooltip = rendered_component.at_css("[id='#{show_button['aria-labelledby']}']")

      expect(tooltip.text).to eq(I18n.t("documents.document_type_actions"))
    end

    it "offers edit, the four move directions and delete", :aggregate_failures do
      expect(rendered_component).to have_link(I18n.t(:button_edit), visible: :all)
      expect(move_items.pluck("data-sortable-lists--item-direction-param")).to eq(%w[top up down bottom])
      expect(rendered_component).to have_link(I18n.t(:button_delete), visible: :all)
    end

    it "keeps the move directions in a submenu the item controller can hide" do
      expect(rendered_component).to have_css("li[data-sortable-lists--item-target~='moveMenu']", visible: :all)
    end

    it "wires every move item to the item controller" do
      expect(move_items.pluck("data-action")).to all(eq("click->sortable-lists--item#move"))
    end

    it "labels the move items with the existing sort translations", :aggregate_failures do
      %i[label_sort_highest label_sort_higher label_sort_lower label_sort_lowest].each do |key|
        expect(rendered_component).to have_button(I18n.t(key), visible: :all)
      end
    end

    it "renders exactly one divider, so hiding the move submenu leaves a single separator" do
      expect(rendered_component).to have_css("li.ActionList-sectionDivider", count: 1, visible: :all)
    end

    it "deletes through the async dialog and posts no legacy move form", :aggregate_failures do
      expect(rendered_component)
        .to have_link(I18n.t(:button_delete),
                      href: "/admin/settings/document_types/#{document_type.id}/delete_dialog",
                      visible: :all)
      expect(rendered_component).to have_no_field("move_to", type: :hidden)
      expect(rendered_component).to have_no_field("position", type: :hidden)
    end
  end
end
