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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackage::PDFExport::StatusReport do
  let(:type) { create(:type, name: "Status Report") }
  let(:project) do
    create(:project,
           types: [type],
           name: "Site Project",
           description: "Electrical installation",
           status_code: :at_risk,
           progress_percent: 60)
  end
  let(:report) { create(:work_package, project:, type:, subject: "November Status Report", description: "Status at the cutoff") }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages export_work_packages] }) }

  before { login_as(user) }

  subject(:pdf_text) do
    export = described_class.new(report).export!
    PDF::Inspector::Text.analyze(export.content).strings.join(" ")
  end

  it "renders the project attributes and the report description" do
    expect(pdf_text).to include(
      "Site Project",
      project.identifier,
      I18n.t("activerecord.attributes.project.status_codes.at_risk"),
      "Electrical installation",
      "November Status Report",
      "Status summary",
      "Status at the cutoff",
      "Project progress",
      "60 %",
      "Report details",
      "Workflow status"
    )
  end

  it "separates the project status from the report workflow" do
    expect(pdf_text.index("Project status")).to be < pdf_text.index("Project attributes")
    expect(pdf_text.index("Report details")).to be < pdf_text.index("Workflow status")
    expect(pdf_text.scan("Project attributes").length).to eq(1)
  end

  context "with an embedded table" do
    let(:query) { create(:global_query, column_names: %i[id subject status]) }
    let!(:outgoing) { create(:work_package, project:, type:, subject: "Selected milestone") }
    let!(:incoming) { create(:work_package, project:, type:, subject: "Selected risk") }
    let!(:unrelated) { create(:work_package, project:, type:, subject: "Unselected work package") }

    before do
      variant = type.default_variant
      variant.attribute_groups = variant.default_attribute_groups + [["Risks and opportunities", [:"query_#{query.id}"]]]
      variant.save!
      create(:relation, from: report, to: outgoing)
      create(:relation, from: incoming, to: report)
    end

    it "uses the configured heading and exports direct relations in both directions" do
      expect(pdf_text).to include("Risks and opportunities", outgoing.subject, incoming.subject)
      expect(pdf_text).not_to include(unrelated.subject)
    end
  end
end
