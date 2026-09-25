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

    it "names the table and indexes its columns for assistive technology" do
      expect(rendered_component).to have_role(:table, accessible_name: "Document types") do |table|
        expect(table["aria-colcount"]).to eq("3")
        expect(table).to have_selector(:columnheader, "Type", colindex: 1)
        expect(table).to have_selector(:columnheader, "Documents", colindex: 2)
        expect(table).to have_css("[role='rowgroup'].op-border-box-table--rows > [role='row']", count: 2)
      end
    end

    it "renders a row per document type", :aggregate_failures do
      expect(rendered_component).to have_selector(:row, "Note")
      expect(rendered_component).to have_selector(:row, "Report")
    end

    it "hides the documents count on small screens but never the name", :aggregate_failures do
      expect(rendered_component)
        .to have_css(".op-border-box-grid__row-item.documents_count.op-border-box-grid__row-item--no-mobile", count: 2)
      expect(rendered_component).to have_no_css(".op-border-box-grid__row-item.name.op-border-box-grid__row-item--no-mobile")
    end

    it_behaves_like "a sortable-lists list",
                    list_type: "document_type",
                    name: "Document types",
                    rows_container: ":scope > .op-border-box-table--rows"
    it_behaves_like "a Border Box Table sortable list", row_count: 2
    it_behaves_like "sortable-lists items", list_type: "document_type" do
      let(:sortable_records) { [note, report] }
    end

    it "leaves the sortable root, its outlets and the move URL to the index wrapper" do
      expect(rendered_component).to have_css("[data-controller~='sortable-lists--list']") do |container|
        expect(container["data-sortable-lists-move-url-template-value"]).to be_nil
        expect(container["data-sortable-lists-sortable-lists--list-outlet"]).to be_nil
        expect(container["data-sortable-lists-sortable-lists--item-outlet"]).to be_nil
      end
      expect(rendered_component).to have_no_css("[data-controller~='sortable-lists']")
    end

    it "identifies each row and drags it whole" do
      [note, report].each do |document_type|
        expect(rendered_component)
          .to have_css(".Box-row[data-sortable-lists--item-id-value='#{document_type.id}']") do |row|
          expect(row["id"]).to eq("document-type-#{document_type.id}")
          expect(row["data-sortable-lists--item-target"]).to eq("preview")
          expect(row["data-test-selector"]).to eq("document-type-row-#{document_type.id}")
        end
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
