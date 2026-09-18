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

  it "links the name to the edit page" do
    expect(rendered_component)
      .to have_link("Note", href: "/admin/settings/document_types/#{document_type.id}/edit")
  end

  it "shows how many documents use the type in the Documents column" do
    create_list(:document, 2, type: document_type)

    expect(rendered_component).to have_css("[role='cell'][aria-colindex='2']", exact_text: "2", normalize_ws: true)
  end

  it "targets the drag handle for the item controller" do
    expect(rendered_component).to have_css(".DragHandle[data-sortable-lists--item-target~='handle']")
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
      expect(rendered_component).to have_css("action-menu.hide-when-print", visible: :all)
      expect(rendered_component).to have_css(".DragHandle.hide-when-print", visible: :all)
    end

    it "sits behind a button named for the document type" do
      expect(rendered_component).to have_button(accessible_name: I18n.t("documents.document_type_actions"))
    end

    # The four directions themselves are covered by the SortableLists::MoveMenu spec.
    it "renders the Move submenu carrying the moveMenu target with the shared move items" do
      expect(rendered_component).to have_css("li[data-sortable-lists--item-target~='moveMenu']", visible: :all) do |item|
        expect(item).to have_css("[role='menuitem']", text: I18n.t(:button_move), visible: :all) do |trigger|
          expect(rendered_component)
            .to have_css("##{trigger['aria-controls']} li[data-sortable-lists--item-target~='moveItem']", count: 4, visible: :all)
        end
      end
    end

    it "renders exactly one divider, so hiding the move submenu leaves a single separator" do
      expect(rendered_component).to have_css("li.ActionList-sectionDivider", count: 1, visible: :all)
    end

    it "keeps Edit and the async-dialog Delete in the menu, without a legacy move form", :aggregate_failures do
      expect(rendered_component)
        .to have_link(I18n.t(:button_edit),
                      href: "/admin/settings/document_types/#{document_type.id}/edit",
                      visible: :all)
      expect(rendered_component)
        .to have_link(I18n.t(:button_delete),
                      href: "/admin/settings/document_types/#{document_type.id}/delete_dialog",
                      visible: :all)
      expect(rendered_component).to have_no_field("move_to", type: :hidden)
      expect(rendered_component).to have_no_field("position", type: :hidden)
    end
  end
end
