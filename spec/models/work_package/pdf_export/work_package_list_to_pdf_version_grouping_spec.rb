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

RSpec.describe WorkPackage::PDFExport::WorkPackageListToPdf,
               "grouped by version",
               with_settings: { work_package_multiple_versions: false } do
  include PDFExportSpecUtils

  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %w[view_work_packages export_work_packages] })
  end
  shared_let(:version) { create(:version, project:, name: "1.0") }
  shared_let(:work_package) do
    create(:work_package,
           project:,
           subject: "Grouped work package",
           start_date: Date.new(2024, 4, 21),
           due_date: Date.new(2024, 4, 23))
  end

  let(:query) do
    build(:query, user:, project:, group_by: "version") do |q|
      q.column_names = %w[id subject]
      q.sort_criteria = [%w[id asc]]
    end
  end
  let(:export) do
    login_as(user)
    described_class.new(query, options)
  end
  let(:pdf_strings) do
    PDF::Inspector::Text
      .analyze(File.read(export.export!.content.path))
      .strings.join(" ").squeeze(" ")
  end

  before do
    create(:work_package_version, work_package:, version:)
  end

  context "with a table export" do
    let(:options) { { pdf_export_type: "table" } }

    it "heads the group with the target version" do
      expect(pdf_strings).to include(
        [version.name,
         column_title("id"), column_title("subject"),
         work_package.display_id.to_s, work_package.subject].join(" ")
      )
    end
  end

  context "with a gantt export" do
    let(:options) { { pdf_export_type: "gantt", gantt_mode: "day", gantt_width: "wide", paper_size: "EXECUTIVE" } }

    it "heads the group with the target version" do
      expect(pdf_strings).to include([version.name, work_package.type.name].join(" "))
    end
  end
end
