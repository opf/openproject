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

RSpec.describe Documents::Admin::DocumentTypes::TableComponent, type: :component do
  subject(:rendered_component) do
    with_request_url("/admin/settings/document_types") do
      render_inline(described_class.new(rows: document_types))
    end
  end

  let!(:note) { create(:document_type, name: "Note", is_default: true) }
  let!(:report) { create(:document_type, name: "Report", active: false) }
  let(:document_types) { DocumentType.reorder(:position) }

  context "with document types" do
    it_behaves_like "rendering Border Box Grid heading", text: "Type"
    it_behaves_like "rendering Border Box Grid heading", text: "Documents"
    it_behaves_like "rendering Border Box Grid mobile heading", text: "Document types"
    it_behaves_like "rendering Border Box Grid rows", row_count: 2, col_count: 2

    it "renders a name and a documents count cell in every row" do
      cells_per_row = rendered_component.css("#document-types-table .op-border-box-table--rows .Box-row").map do |row|
        row.css(".op-border-box-grid__row-item").size
      end

      expect(cells_per_row).to eq([2, 2])
    end

    it "renders a row per document type", :aggregate_failures do
      expect(rendered_component).to have_css(".Box-row", text: "Note")
      expect(rendered_component).to have_css(".Box-row", text: "Report")
    end

    it "names the table and indexes its columns for assistive technology", :aggregate_failures do
      expect(rendered_component)
        .to have_css("#document-types-table[role='table'][aria-label='Document types'][aria-colcount='3']")
      expect(rendered_component).to have_css("[role='columnheader'][aria-colindex='1']", text: "Type")
      expect(rendered_component).to have_css("[role='columnheader'][aria-colindex='2']", text: "Documents")
      expect(rendered_component).to have_css(".op-border-box-table--rows[role='rowgroup'] > [role='row']", count: 2)
    end

    it "hides the documents count on small screens but never the name", :aggregate_failures do
      expect(rendered_component)
        .to have_css(".op-border-box-grid__row-item.documents_count.op-border-box-grid__row-item--no-mobile", count: 2)
      expect(rendered_component).to have_no_css(".op-border-box-grid__row-item.name.op-border-box-grid__row-item--no-mobile")
    end

    it "wires the table container as the sortable list", :aggregate_failures do
      container = rendered_component.at_css("#document-types-table")

      expect(container["data-controller"]).to eq("sortable-lists--list")
      expect(container["data-sortable-lists--list-type-value"]).to eq("document_type")
      expect(container["data-sortable-lists--list-accepted-type-value"]).to eq("document_type")
      expect(container["data-sortable-lists--list-name-value"]).to eq("Document types")
    end

    it "leaves the sortable root, its outlets and the move URL to the index wrapper", :aggregate_failures do
      container = rendered_component.at_css("#document-types-table")

      expect(container["data-sortable-lists-move-url-template-value"]).to be_nil
      expect(container["data-sortable-lists-sortable-lists--list-outlet"]).to be_nil
      expect(container["data-sortable-lists-sortable-lists--item-outlet"]).to be_nil
      expect(rendered_component).to have_no_css("[data-controller~='sortable-lists']")
    end

    it "points the list at the rows container the table really uses", :aggregate_failures do
      container = rendered_component.at_css("#document-types-table")

      expect(container["data-sortable-lists--list-rows-container-element"])
        .to eq(":scope > .op-border-box-table--rows")
      expect(rendered_component)
        .to have_css("#document-types-table > .op-border-box-table--rows > .Box-row", count: 2)
      expect(rendered_component).to have_no_css("#document-types-table > ul")
    end

    it "renders each document type as an identified sortable row", :aggregate_failures do
      [note, report].each do |document_type|
        row = rendered_component.at_css(".Box-row[data-sortable-lists--item-id-value='#{document_type.id}']")

        expect(row["id"]).to eq("document-type-#{document_type.id}")
        expect(row["data-controller"]).to eq("sortable-lists--item")
        expect(row["data-sortable-lists--item-type-value"]).to eq("document_type")
        expect(row["data-sortable-lists--item-label-value"]).to eq(document_type.name)
        expect(row["data-sortable-lists--item-target"]).to eq("preview")
        expect(row["data-test-selector"]).to eq("document-type-row-#{document_type.id}")
      end
    end

    it "drops the bespoke grid the table replaces", :aggregate_failures do
      expect(rendered_component).to have_no_css(".op-documents-types-list--header")
      expect(rendered_component).to have_no_css(".op-documents-types-list--item")
    end
  end

  context "without document types" do
    let(:document_types) { DocumentType.where(id: nil) }

    it "keeps today's blank-state wording and renders no sortable rows", :aggregate_failures do
      expect(rendered_component).to have_text(I18n.t(:no_results_title_text))
      expect(rendered_component).to have_no_text(I18n.t(:label_nothing_display))
      expect(rendered_component).to have_no_css("[data-controller~='sortable-lists--item']")
    end
  end
end
