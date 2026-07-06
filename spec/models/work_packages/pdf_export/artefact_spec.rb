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
             project => %w[view_work_packages export_work_packages]
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
end
