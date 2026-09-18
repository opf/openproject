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

  it "keeps the sortable root on the wrapper, which the morph never replaces", :aggregate_failures do
    wrapper = rendered_component.at_css("#documents-admin-document-types-index-component")

    expect(wrapper["data-controller"]).to eq("sortable-lists")
    expect(wrapper["data-sortable-lists-move-url-template-value"])
      .to eq("/admin/settings/document_types/{id}/move")
    expect(wrapper["data-sortable-lists-sortable-lists--list-outlet"])
      .to eq("#documents-admin-document-types-index-component [data-controller~='sortable-lists--list']")
    expect(wrapper["data-sortable-lists-sortable-lists--item-outlet"])
      .to eq("#documents-admin-document-types-index-component [data-controller~='sortable-lists--item']")
  end

  it "resolves both outlets inside the wrapper", :aggregate_failures do
    expect(rendered_component)
      .to have_css("#documents-admin-document-types-index-component [data-controller~='sortable-lists--list']",
                   count: 1)
    expect(rendered_component)
      .to have_css("#documents-admin-document-types-index-component [data-controller~='sortable-lists--item']",
                   count: 2)
  end

  it "sets the rows container the list controller must use" do
    list = rendered_component.at_css("[data-controller~='sortable-lists--list']")

    expect(list["data-sortable-lists--list-rows-container-element"]).to eq(":scope > .op-border-box-table--rows")
  end

  it "offers adding a document type above the list" do
    expect(rendered_component).to have_test_selector("add-document-type-button")
  end

  it "renders the document types in the shared table", :aggregate_failures do
    expect(rendered_component).to have_css("#document-types-table[role='table']")
    expect(rendered_component).to have_css(".op-border-box-table--rows > .Box-row", count: 2)
    expect(rendered_component).to have_css(".Box-row", text: "Note")
    expect(rendered_component).to have_css(".Box-row", text: "Report")
  end

  it "drops the bespoke grid and its markup", :aggregate_failures do
    expect(rendered_component).to have_no_css(".op-documents-types-list--header")
    expect(rendered_component).to have_no_css(".op-documents-types-list--item")
  end

  it "leaves the list wiring to the table container", :aggregate_failures do
    wrapper = rendered_component.at_css("#documents-admin-document-types-index-component")
    container = rendered_component.at_css("#document-types-table")

    expect(wrapper["data-sortable-lists--list-type-value"]).to be_nil
    expect(container["data-controller"]).to eq("sortable-lists--list")
    expect(container["data-sortable-lists--list-type-value"]).to eq("document_type")
  end
end
