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
  subject(:rendered_component) do
    with_request_url("/admin/settings/document_types") do
      render_inline(described_class.new(enumerations: DocumentType.reorder(:position)))
    end
  end

  let!(:note) { create(:document_type, name: "Note") }
  let!(:report) { create(:document_type, name: "Report") }

  it "keeps the wrapper the move response morphs" do
    expect(rendered_component).to have_css("#documents-admin-document-types-index-component")
  end

  # The sortable root stays on the wrapper, which the morph never replaces.
  it_behaves_like "a sortable-lists root",
                  wrapper_id: "documents-admin-document-types-index-component",
                  move_url_template: "/admin/settings/document_types/{id}/move"
  it_behaves_like "no legacy drag-and-drop wiring"

  it "resolves both outlets inside the wrapper", :aggregate_failures do
    expect(rendered_component)
      .to have_css("#documents-admin-document-types-index-component [data-controller~='sortable-lists--list']",
                   count: 1)
    expect(rendered_component)
      .to have_css("#documents-admin-document-types-index-component [data-controller~='sortable-lists--item']",
                   count: 2)
  end

  it_behaves_like "a sortable-lists list",
                  list_type: "document_type",
                  name: "Document types",
                  rows_container: ":scope > .op-border-box-table--rows"

  it "leaves the list wiring to the table container" do
    expect(rendered_component).to have_css("#documents-admin-document-types-index-component") do |wrapper|
      expect(wrapper["data-sortable-lists--list-type-value"]).to be_nil
      expect(wrapper["data-sortable-lists--list-rows-container-element"]).to be_nil
    end
  end

  it "offers adding a document type above the list" do
    expect(rendered_component).to have_test_selector("add-document-type-button")
  end

  it "renders the document types in the shared table" do
    expect(rendered_component).to have_role(:table, accessible_name: "Document types") do |table|
      expect(table).to have_selector(:row, "Note")
      expect(table).to have_selector(:row, "Report")
    end
  end

  it "drops the bespoke grid and its markup", :aggregate_failures do
    expect(rendered_component).to have_no_css(".op-documents-types-list--header")
    expect(rendered_component).to have_no_css(".op-documents-types-list--item")
  end
end
