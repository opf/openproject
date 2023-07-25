#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'
require 'pdf/inspector'

RSpec.describe WorkPackage::PDFExport::WorkPackageListToPdf do
  include Redmine::I18n
  let(:type1) { create(:type_standard) }
  let(:type2) { create(:type_bug) }
  let(:project) { create(:project, name: 'Foo Bla. Report No. 4/2021 with/for Case 42', types: [type1, type2]) }
  let(:user) do
    create(:user,
           member_in_project: project,
           member_with_permissions: %w[view_work_packages export_work_packages])
  end
  let(:column_names) { [:id, :subject, :status, :story_points] }

  def work_package_columns(wp)
    [wp.id.to_s, wp.subject, wp.status.name, wp.story_points.to_s]
  end

  def work_package_details(wp, nr)
    ["#{nr}.", wp.subject,
     'ID', wp.id.to_s,
     'STATUS', wp.status.name,
     'STORY POINTS', wp.story_points.to_s,
     'Description',
     wp.description]
  end

  let(:export_time) {
    DateTime.new(2023, 6, 30, 23, 59, 00, '+00:00')
  }
  let(:export_time_formatted) {
    format_time(export_time, true)
  }

  let(:work_package1) do
    create(:work_package,
           project:,
           type: type1,
           subject: 'Work package 1',
           story_points: 1,
           description: 'This is a description'
    )
  end
  let(:work_package2) do
    create(:work_package, project:,
           type: type2,
           subject: 'Work package 2',
           story_points: 2,
           description: 'This is work package 2'
    )
  end
  let(:work_packages) do
    [work_package1, work_package2]
  end
  let(:query_attributes) { {} }
  let!(:query) do
    build(:query, user:, project:, **query_attributes).tap do |q|
      q.column_names = column_names
      q.sort_criteria = [%w[id asc]]
    end
  end
  let(:column_titles) { column_names.map { |name| WorkPackage.human_attribute_name(name).upcase } }
  let(:options) { {} }

  let(:export) do
    login_as(user)
    work_packages
    described_class.new(query, options)
  end

  let(:export_pdf) do
    Timecop.freeze(export_time) do
      export.export!
    end
  end

  def open_temp_pdf
    cmd = "open -a Preview #{export_pdf.content.path}"
    puts cmd
    `#{cmd}`
  end

  subject(:pdf) do
    PDF::Inspector::Text.analyze(File.read(export_pdf.content.path))
  end

  describe 'with a request for a PDF table' do
    it 'contains correct data' do
      expect(pdf.strings).to eq([
                                  query.name,
                                  *column_titles,
                                  *work_package_columns(work_package1),
                                  *work_package_columns(work_package2),
                                  '1/1', export_time_formatted, query.name
                                ])
    end
  end

  describe 'with a request for a PDF table grouped' do
    let(:query_attributes) { { group_by: 'type' } }

    it 'contains correct data' do
      expect(pdf.strings).to eq([
                                  query.name,
                                  type1.name,
                                  *column_titles,
                                  *work_package_columns(work_package1),
                                  type2.name,
                                  *column_titles,
                                  *work_package_columns(work_package2),
                                  '1/1', export_time_formatted, query.name
                                ])
    end
  end

  describe 'with a request for a PDF table grouped with sums' do
    let(:query_attributes) { { group_by: 'type', display_sums: true } }

    it 'contains correct data' do
      expect(pdf.strings).to eq([
                                  query.name,
                                  type1.name,
                                  *column_titles,
                                  *work_package_columns(work_package1),
                                  "Sum", work_package1.story_points.to_s,
                                  type2.name,
                                  *column_titles,
                                  *work_package_columns(work_package2),
                                  "Sum", work_package2.story_points.to_s,
                                  '1/1', export_time_formatted, query.name
                                ])
    end
  end

  describe 'with a request for a PDF Report' do
    let(:options) { { show_report: true } }

    it 'contains correct data' do
      expect(pdf.strings).to eq([
                                  query.name,
                                  '1.', '2', work_package1.subject,
                                  '2.', '2', work_package2.subject,
                                  '1/2', export_time_formatted, query.name,
                                  *work_package_details(work_package1, 1),
                                  *work_package_details(work_package2, 2),
                                  '2/2', export_time_formatted, query.name
                                ])
    end
  end

  describe 'with a request for a PDF Report with sums' do
    let(:options) { { show_report: true } }
    let(:query_attributes) { { display_sums: true } }

    it 'contains correct data' do
      expect(pdf.strings).to eq([
                                  query.name,
                                  '1.', '2', work_package1.subject,
                                  '2.', '2', work_package2.subject,
                                  '1/2', export_time_formatted, query.name,
                                  "Overview",
                                  "STORY POINTS", "Sum", (work_package1.story_points + work_package2.story_points).to_s,
                                  *work_package_details(work_package1, 1),
                                  *work_package_details(work_package2, 2),
                                  '2/2', export_time_formatted, query.name
                                ])
    end
  end

  describe 'with a request for a PDF Report grouped with sums' do
    let(:options) { { show_report: true } }
    let(:query_attributes) { { display_sums: true, group_by: 'type' } }

    it 'contains correct data' do
      expect(pdf.strings).to eq([
                                  query.name,
                                  '1.', '2', work_package1.subject,
                                  '2.', '2', work_package2.subject,
                                  '1/2', export_time_formatted, query.name,
                                  "Overview",
                                  "TYPE", "STORY POINTS",
                                  type1.name, work_package1.story_points.to_s,
                                  type2.name, work_package2.story_points.to_s,
                                  "Sum", (work_package1.story_points + work_package2.story_points).to_s,
                                  *work_package_details(work_package1, 1),
                                  *work_package_details(work_package2, 2),
                                  '2/2', export_time_formatted, query.name
                                ])
    end
  end
end
