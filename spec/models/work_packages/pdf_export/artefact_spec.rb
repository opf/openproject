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

RSpec.describe WorkPackage::PDFExport::Artefact do
  include Redmine::I18n
  include PDFExportSpecUtils

  let(:type) { create(:type_bug) }
  let(:status) { create(:status, name: "In progress", is_default: true) }
  let(:project) do
    create(:project,
           name: "Artefact project",
           types: [type],
           public: true,
           active: true)
  end
  let(:user) do
    create(:user,
           member_with_permissions: {
             project => %w[view_work_packages export_work_packages view_project_attributes]
           })
  end
  let(:work_package) do
    create(:work_package,
           project:,
           type:,
           status:,
           subject: "The artefact subject",
           description: "A **rich** text description")
  end
  let(:export_time) { DateTime.new(2023, 6, 30, 23, 59) }
  let(:options) { {} }
  let(:exporter) { described_class.new(work_package, options) }
  let(:export_pdf) do
    login_as(user)
    Timecop.freeze(export_time) { exporter.export! }
  end

  subject(:pdf_strings) do
    content = export_pdf.content
    PDF::Inspector::Text.analyze(content).strings
  end

  it "produces a valid PDF" do
    expect(export_pdf).to be_a(Exports::Result)
    expect(export_pdf.content).to start_with("%PDF")
  end

  it "renders the cover heading, subject and description" do
    joined = pdf_strings.join(" ")
    expect(joined).to include("#{type.name} #{work_package.formatted_id}")
    expect(joined).to include(work_package.subject)
    expect(joined).to include(exporter.prawn_badge_text_stuffing(work_package.status.name))
    expect(joined).to include("rich")
  end

  it "builds a filename from the work package attributes" do
    expect(exporter.title).to include(project.identifier)
    expect(exporter.title).to end_with(".pdf")
  end

  describe "project attribute sections" do
    let(:section_a) { create(:project_custom_field_section, name: "Section A") }
    let(:section_b) { create(:project_custom_field_section, name: "Section B") }
    let!(:string_cf) do
      create(:string_project_custom_field,
             name: "Artefact string field",
             projects: [project],
             project_custom_field_section: section_a)
    end
    let!(:bool_cf) do
      create(:boolean_project_custom_field,
             name: "Artefact bool field",
             projects: [project],
             project_custom_field_section: section_b)
    end
    let!(:unmapped_cf) do
      # enabled for the project but not for the work package type => must not appear
      create(:string_project_custom_field,
             name: "Not on this type",
             projects: [project],
             project_custom_field_section: section_a)
    end

    before do
      type.project_custom_fields << string_cf
      type.project_custom_fields << bool_cf
      project.update!(custom_field_values: { string_cf.id => "Artefact value", bool_cf.id => true })
    end

    it "renders the sections and their project attributes grouped by section" do
      joined = pdf_strings.join(" ")
      expect(joined).to include("Section A", "Section B")
      expect(joined).to include(string_cf.name, "Artefact value")
      expect(joined).to include(bool_cf.name, "Yes")
    end

    it "omits attributes not mapped to the work package type" do
      expect(pdf_strings.join(" ")).not_to include(unmapped_cf.name)
    end
  end
end
