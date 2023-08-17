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

RSpec.describe WorkPackage::PDFExport::WorkPackageListToPdf do
  include Redmine::I18n
  include PDFExportSpecUtils
  let(:type_standard) { create(:type_standard) }
  let(:type_bug) { create(:type_bug) }
  let!(:list_custom_field) do
    create(:list_wp_custom_field,
           types: [type_standard, type_bug],
           multi_value: true,
           possible_values: %w[Foo Bar])
  end
  let(:custom_value_first) do
    create(:work_package_custom_value,
           custom_field: list_custom_field,
           value: list_custom_field.custom_options.first.id)
  end
  let(:types) { [type_standard, type_bug] }
  let(:project) do
    create(:project,
           name: 'Foo Bla. Report No. 4/2021 with/for Case 42',
           types:,
           work_package_custom_fields: [list_custom_field])
  end
  let(:user) do
    create(:user,
           member_in_project: project,
           member_with_permissions: %w[view_work_packages export_work_packages])
  end
  let(:export_time) { DateTime.new(2023, 6, 30, 23, 59) }
  let(:export_time_formatted) { format_time(export_time, true) }
  let(:work_package_parent) do
    create(:work_package,
           project:,
           type: type_standard,
           subject: 'Work package 1',
           story_points: 1,
           description: 'This is a description',
           list_custom_field.attribute_name => [
             list_custom_field.value_of('Foo'),
             list_custom_field.value_of('Bar')
           ])
  end
  let(:work_package_child) do
    create(:work_package,
           project:,
           parent: work_package_parent,
           type: type_bug,
           subject: 'Work package 2',
           story_points: 2,
           description: 'This is work package 2',
           list_custom_field.attribute_name => list_custom_field.value_of('Foo'))
  end
  let(:work_packages) do
    [work_package_parent, work_package_child]
  end
  let(:query_attributes) { {} }
  let!(:query) do
    build(:query, user:, project:, **query_attributes).tap do |q|
      q.column_names = column_names
      q.sort_criteria = [%w[id asc]]
    end
  end
  let(:column_titles) { column_names.map { |name| column_title(name) } }
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
  let(:column_names) { %w[id subject status story_points] }

  def work_packages_sum
    work_package_parent.story_points + work_package_child.story_points
  end

  def work_package_columns(work_package)
    [work_package.id.to_s, work_package.subject, work_package.status.name, work_package.story_points.to_s]
  end

  def work_package_details(work_package, index)
    ["#{index}.", work_package.subject,
     column_title(:id), work_package.id.to_s,
     column_title(:status), work_package.status.name,
     column_title(:story_points), work_package.story_points.to_s,
     label_title(:description), work_package.description]
  end

  def cover_page_content
    [project.name, query.name, user.name, export_time_formatted]
  end

  def show
    cmd = "open -a Preview #{export_pdf.content.path}"
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
                                  *work_package_columns(work_package_parent),
                                  *work_package_columns(work_package_child),
                                  '1/1', export_time_formatted, query.name
                                ])
    end
  end

  describe 'with a request for a PDF table grouped' do
    let(:query_attributes) { { group_by: 'type' } }

    it 'contains correct data' do
      expect(pdf.strings).to eq([
                                  query.name,
                                  work_package_parent.type.name,
                                  *column_titles,
                                  *work_package_columns(work_package_parent),
                                  work_package_child.type.name,
                                  *column_titles,
                                  *work_package_columns(work_package_child),
                                  '1/1', export_time_formatted, query.name
                                ])
    end
  end

  describe 'with a request for a PDF table grouped with sums' do
    let(:query_attributes) { { group_by: 'type', display_sums: true } }

    it 'contains correct data' do
      expect(pdf.strings).to eq([
                                  query.name,
                                  work_package_parent.type.name,
                                  *column_titles,
                                  *work_package_columns(work_package_parent),
                                  I18n.t('js.label_sum'), work_package_parent.story_points.to_s,
                                  work_package_child.type.name,
                                  *column_titles,
                                  *work_package_columns(work_package_child),
                                  I18n.t('js.label_sum'), work_package_child.story_points.to_s,
                                  '1/1', export_time_formatted, query.name
                                ])
    end
  end

  describe 'with a request for a PDF table grouped by a custom field with sums' do
    let(:query_attributes) { { group_by: list_custom_field.column_name, display_sums: true } }

    it 'contains correct data' do
      expect(pdf.strings).to eq([
                                  query.name,
                                  "Foo",
                                  *column_titles,
                                  *work_package_columns(work_package_child),
                                  I18n.t('js.label_sum'), work_package_child.story_points.to_s,
                                  "Foo, Bar",
                                  *column_titles,
                                  *work_package_columns(work_package_parent),
                                  I18n.t('js.label_sum'), work_package_parent.story_points.to_s,
                                  '1/1', export_time_formatted, query.name
                                ])
    end
  end

  describe 'with a request for a PDF Report' do
    let(:options) { { show_report: true } }

    it 'contains correct data' do
      expect(pdf.strings).to eq([
                                  *cover_page_content,
                                  query.name,
                                  '1.', '2', work_package_parent.subject,
                                  '2.', '2', work_package_child.subject,
                                  '1/2', export_time_formatted, query.name,
                                  *work_package_details(work_package_parent, "1"),
                                  *work_package_details(work_package_child, "2"),
                                  '2/2', export_time_formatted, query.name
                                ])
    end
  end

  describe 'with a request for a PDF Report with hierarchies' do
    let(:options) { { show_report: true } }
    let(:query_attributes) { { show_hierarchies: true } }

    it 'contains correct data' do
      expect(pdf.strings).to eq([
                                  *cover_page_content,
                                  query.name,
                                  '1.', '2', work_package_parent.subject,
                                  '1.1.', '2', work_package_child.subject,
                                  '1/2', export_time_formatted, query.name,
                                  *work_package_details(work_package_parent, '1'),
                                  *work_package_details(work_package_child, '1.1'),
                                  '2/2', export_time_formatted, query.name
                                ])
    end
  end

  describe 'with a request for a PDF Report with sums' do
    let(:options) { { show_report: true } }
    let(:query_attributes) { { display_sums: true } }

    it 'contains correct data' do
      expect(pdf.strings).to eq([
                                  *cover_page_content,
                                  query.name,
                                  '1.', '2', work_package_parent.subject,
                                  '2.', '2', work_package_child.subject,
                                  '1/2', export_time_formatted, query.name,
                                  I18n.t('js.work_packages.tabs.overview'),
                                  column_title(:story_points),
                                  I18n.t('js.label_sum'), work_packages_sum.to_s,
                                  *work_package_details(work_package_parent, "1"),
                                  *work_package_details(work_package_child, "2"),
                                  '2/2', export_time_formatted, query.name
                                ])
    end
  end

  describe 'with a request for a PDF Report grouped with sums' do
    let(:options) { { show_report: true } }
    let(:query_attributes) { { display_sums: true, group_by: 'type' } }

    it 'contains correct data' do
      expect(pdf.strings).to eq([
                                  *cover_page_content,
                                  query.name,
                                  '1.', '2', work_package_parent.subject,
                                  '2.', '2', work_package_child.subject,
                                  '1/2', export_time_formatted, query.name,
                                  I18n.t('js.work_packages.tabs.overview'),
                                  column_title(:type), column_title(:story_points),
                                  work_package_parent.type.name, work_package_parent.story_points.to_s,
                                  work_package_child.type.name, work_package_child.story_points.to_s,
                                  I18n.t('js.label_sum'), work_packages_sum.to_s,
                                  *work_package_details(work_package_parent, "1"),
                                  *work_package_details(work_package_child, "2"),
                                  '2/2', export_time_formatted, query.name
                                ])
    end
  end

  describe 'with a request for a PDF Report grouped by a custom field with sums' do
    let(:options) { { show_report: true } }
    let(:query_attributes) { { display_sums: true, group_by: list_custom_field.column_name } }

    it 'contains correct data' do
      expect(pdf.strings).to eq([
                                  *cover_page_content,
                                  query.name,
                                  '1.', '2', work_package_child.subject,
                                  '2.', '2', work_package_parent.subject,
                                  '1/2', export_time_formatted, query.name,
                                  I18n.t('js.work_packages.tabs.overview'),
                                  list_custom_field.name.upcase, column_title(:story_points),

                                  "Foo", work_package_child.story_points.to_s,
                                  "Foo, Bar", work_package_parent.story_points.to_s,
                                  I18n.t('js.label_sum'), work_packages_sum.to_s,

                                  *work_package_details(work_package_child, "1"),
                                  *work_package_details(work_package_parent, "2"),
                                  '2/2', export_time_formatted, query.name
                                ])
    end
  end
end
