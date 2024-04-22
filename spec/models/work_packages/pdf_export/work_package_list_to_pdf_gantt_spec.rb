#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe WorkPackage::PDFExport::WorkPackageListToPdf do
  include Redmine::I18n
  include PDFExportSpecUtils
  let(:type_standard) { create(:type_standard, color: create(:color)) }
  let!(:type_milestone) { create(:type, name: "Milestone", is_milestone: true, color: create(:color)) }
  let(:types) { [type_standard, type_milestone] }
  let(:project) do
    create(:project, name: "Foo Bla. Report No. 4/2021 with/for Case 42", types: types)
  end
  let(:user) do
    create(:user,
           member_with_permissions: { project => %w[view_work_packages export_work_packages] })
  end
  let(:options) { { gantt: true } }
  let(:query_attributes) { {} }
  let(:column_names) { %w[id subject status] }
  let!(:query) do
    build(:query, user:, project:, **query_attributes).tap do |q|
      q.column_names = column_names
      q.sort_criteria = [%w[id asc]]
    end
  end
  let(:export_time) { DateTime.new(2024, 4, 22, 12, 37) }
  let(:export_time_formatted) { format_time(export_time, true) }
  let(:export) do
    login_as(user)
    work_packages
    relation
    described_class.new(query, options)
  end
  let(:export_pdf) do
    Timecop.freeze(export_time) do
      export.export!
    end
  end
  let(:relation) do
    create(:relation,
           from: work_package_milestone,
           to: work_package_task,
           relation_type: Relation::TYPE_FOLLOWS)
  end
  let(:work_package_task_start) do
    Date.new(2024, 4, 21)
  end
  let(:work_package_task_due) do
    Date.new(2024, 4, 21)
  end
  let(:work_package_milestone_start) do
    nil
  end
  let(:work_package_milestone_due) do
    Date.new(2024, 4, 23)
  end
  let(:work_package_task) do
    create(:work_package,
           project:,
           type: type_standard,
           subject: "Work package 1",
           start_date: work_package_task_start,
           due_date: work_package_task_due)
  end
  let(:work_package_milestone) do
    create(:work_package,
           project:,
           type: type_milestone,
           subject: "Work package 2",
           start_date: work_package_milestone_start,
           due_date: work_package_milestone_due)
  end
  let(:filler_work_packages) do
    Array.new(50) { create(:work_package, project:, subject: "Work package Filler",
                           start_date: work_package_task_start, due_date: work_package_task_due, type: type_standard) }
  end

  let(:work_packages) do
    [work_package_task, work_package_milestone]
  end

  def show
    cmd = "open -a Preview #{export_pdf.content.path}"
    `#{cmd}`
  end

  def wp_title_column(wp)
    "#{wp.type} ##{wp.id} - #{wp.subject}"
  end

  subject(:pdf_strings) do
    # Joining the results for comparison since word wrapping leads to a different array for the same content
    PDF::Inspector::Text.analyze(File.read(export_pdf.content.path)).strings.join(" ").squeeze(" ")
  end

  describe "with a request for a PDF gantt" do
    it "contains correct data" do
      expect(pdf_strings).to eq [
                                  query.name,
                                  "2024 Apr 21 22 23", # header columns
                                  wp_title_column(work_package_task),
                                  wp_title_column(work_package_milestone),
                                  "1/1", export_time_formatted, query.name
                                ].join(" ")
    end
  end

  describe "with a request for a PDF gantt split on multiple horizontal pages" do
    let(:work_package_milestone_due) do
      Date.new(2024, 5, 8)
    end
    it "contains correct data" do
      expect(pdf_strings).to eq [
                                  query.name,
                                  "2024 Apr May 21 22 23 24 25 26 27 28 29 30 1 2 3 4 5", # header columns
                                  wp_title_column(work_package_task),
                                  wp_title_column(work_package_milestone),
                                  "1/2", export_time_formatted, query.name,
                                  "2024 May 6 7 8", # header columns
                                  "2/2", export_time_formatted, query.name,
                                ].join(" ")
    end
  end

  describe "with a request for a PDF gantt split on multiple horizontal and vertical pages" do
    let(:work_packages) do
      [work_package_task] + filler_work_packages + [work_package_milestone]
    end
    let(:work_package_milestone_due) do
      Date.new(2024, 5, 8)
    end
    it "contains correct data" do
      test = [
        query.name, "2024 Apr May 21 22 23 24 25 26 27 28 29 30 1 2 3 4 5", # header columns
        wp_title_column(work_package_task),
        filler_work_packages.slice(0, 17).map { |wp| wp_title_column(wp) },
        "1/6", export_time_formatted, query.name,

        "2024 May 6 7 8", # header columns
        "2/6", export_time_formatted, query.name,

        query.name, "2024 Apr May 21 22 23 24 25 26 27 28 29 30 1 2 3 4 5", # header columns
        filler_work_packages.slice(17, 18).map { |wp| wp_title_column(wp) },
        "3/6", export_time_formatted, query.name,

        "2024 May 6 7 8", # header columns
        "4/6", export_time_formatted, query.name,

        query.name, "2024 Apr May 21 22 23 24 25 26 27 28 29 30 1 2 3 4 5", # header columns
        filler_work_packages.slice(35, 15).map { |wp| wp_title_column(wp) },
        wp_title_column(work_package_milestone),
        "5/6", export_time_formatted, query.name,

        "2024 May 6 7 8", # header columns
        "6/6", export_time_formatted, query.name
      ].flatten.join(" ")
      expect(pdf_strings).to eq test
    end
  end
end
