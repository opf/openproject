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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackage::PDFExport::ZendisArtefact do
  include Redmine::I18n
  include PDFExportSpecUtils

  let(:content_field) { create(:issue_custom_field, :text, name: "Change proposal", is_for_all: true) }
  let(:address_field) { create(:issue_custom_field, :text, name: "Contact", is_for_all: true) }
  let(:type) { create(:type_bug, custom_fields: [content_field, address_field]) }
  let(:project) { create(:project, types: [type], public: true) }
  let(:user) { create(:admin) }
  let(:work_package) do
    create(:work_package, project:, type:, subject: "Finalising the product",
           description: "Do not export this primary description",
           custom_values: { content_field.id => "The **proposed** change", address_field.id => "Example address" })
  end
  let(:options) { { address_custom_field_id: address_field.id, include_lifecycle: false, include_budget: false } }
  let(:exporter) { described_class.new(work_package, options) }
  let(:export_pdf) { exporter.export! }
  let(:pdf_strings) { PDF::Inspector::Text.analyze(export_pdf.content).strings }

  before do
    login_as(user)
    work_package.update_columns(updated_at: Time.zone.local(2026, 10, 2, 12))
  end

  it "renders the type and display ID, subject and configured long text fields" do
    expect(export_pdf.content).to start_with("%PDF")
    expect(pdf_strings.join(" ")).to include("#{type.name} #{work_package.display_id}", work_package.subject,
                                             content_field.name, "proposed")
    expect(pdf_strings.join(" ")).not_to include(work_package.description)
  end

  it "uses the last change for the document date and omits status badges" do
    expect(pdf_strings.join(" ")).to include(exporter.document_date)
    expect(exporter.document_date).to include(format_date(work_package.updated_at))
    expect(pdf_strings.join(" ")).not_to include(exporter.prawn_badge_text_stuffing(work_package.status.name))
  end

  it "renders the address once on a separate final page and indexes it" do
    pages = PDF::Reader.new(StringIO.new(export_pdf.content)).pages
    expect(pages.last.text).to include("Contact", "Example address")
    expect(pages[0...-1].map(&:text).join).not_to include("Example address")
    expect(exporter.toc_entries.last).to include(key: "contact", page_number: pages.length)
    expect(pages.last.text).to include("#{pages.length} / #{pages.length}")
  end

  context "without an address mapping" do
    let(:options) { { toc: false, include_lifecycle: false, include_budget: false } }

    it "does not append a contact page" do
      expect(exporter.toc_entries.map { |entry| entry[:key] }).not_to include("contact")
      expect(pdf_strings.join(" ")).to include("Example address")
    end
  end

  context "with an invalid address mapping" do
    let(:options) { { address_custom_field_id: "invalid" } }

    it "ignores the mapping" do
      expect(export_pdf.content).to start_with("%PDF")
      expect(exporter.toc_entries.map { |entry| entry[:key] }).not_to include("contact")
    end
  end

  context "with related work packages" do
    let(:query) do
      create(:global_query, column_names: %i[id subject]).tap do |query|
        query.add_filter("parent", "=", [Queries::Filters::TemplatedValue::KEY])
        query.save!
      end
    end
    let!(:child) do
      create(:work_package, project:, type:, parent: work_package, subject: "Related deliverable",
             description: "Related description", custom_values: { content_field.id => "Related long text" })
    end

    before do
      variant = type.default_variant
      variant.attribute_groups = variant.default_attribute_groups + [["Related work", [:"query_#{query.id}"]]]
      variant.save!
    end

    it "keeps the PMflex rendering of descriptions and long text custom fields" do
      expect(pdf_strings.join(" ")).to include(child.subject, "Related description", "Related long text")
    end
  end
end
