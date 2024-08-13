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

module PDF
  class Inspector
    class Generic < Inspector
      attr_reader :calls

      def initialize
        super
        @calls = []
      end

      def method_missing(*args)
        @calls << args
      end

      def respond_to_missing?(*)
        true
      end

      def respond_to?(*)
        true
      end
    end
  end
end

RSpec.describe WorkPackage::PDFExport::WorkPackageListToPdf do
  include Redmine::I18n
  include PDFExportSpecUtils
  let!(:status_new) { create(:status, name: "New", is_default: true) }
  let(:type_standard) { create(:type_standard, name: "Standard", color: create(:color, hexcode: "#FFFF00")) }
  let(:type_bug) { create(:type_bug, name: "Bug", color: create(:color, hexcode: "#00FFFF")) }
  let!(:type_milestone) { create(:type, name: "Milestone", is_milestone: true, color: create(:color, hexcode: "#FF0000")) }
  let(:types) { [type_standard, type_milestone] }
  let(:project) do
    create(:project, name: "Foo Bla. Report No. 4/2021 with/for Case 42", types:)
  end
  let(:user) do
    create(:user,
           member_with_permissions: { project => %w[view_work_packages export_work_packages] })
  end
  let(:options) { { pdf_export_type: "gantt", gantt_mode: "day", gantt_width: "wide", paper_size: "EXECUTIVE" } }
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
           status: status_new,
           type: type_standard,
           subject: "Work package 1",
           start_date: work_package_task_start,
           due_date: work_package_task_due)
  end
  let(:work_package_milestone) do
    create(:work_package,
           project:,
           type: type_milestone,
           status: status_new,
           subject: "Work package 2",
           start_date: work_package_milestone_start,
           due_date: work_package_milestone_due)
  end
  let(:filler_work_packages) do
    Array.new(50) do
      create(:work_package,
             project:,
             status: status_new,
             subject: "Work package Filler",
             start_date: work_package_task_start,
             due_date: work_package_task_due,
             type: type_bug)
    end
  end

  let(:work_packages) do
    [work_package_task, work_package_milestone]
  end

  def show_pdf
    cmd = "open -a Preview #{export_pdf.content.path}"
    `#{cmd}`
  end

  def show_calls
    pp pdf[:calls]
  end

  def wp_title_dates(work_package)
    if work_package.start_date == work_package.due_date
      format_date(work_package.start_date)
    else
      formatted_start_date = format_date(work_package.start_date) || "no start date"
      formatted_due_date = format_date(work_package.due_date) || "no start date"
      "#{formatted_start_date} - #{formatted_due_date}"
    end
  end

  def wp_title_column(work_package)
    "#{work_package.type} ##{work_package.id} • #{work_package.status} • #{wp_title_dates work_package} #{work_package.subject}"
  end

  subject(:pdf) do
    content = File.read(export_pdf.content.path)
    {
      # Joining the results for comparison since word wrapping leads to a different array for the same content
      strings: PDF::Inspector::Text.analyze(content).strings.join(" ").squeeze(" "),
      calls: PDF::Inspector::Generic.analyze(content).calls
    }
  end

  def include_calls?(calls_to_find, all_calls)
    positions = all_calls.each_index.select { |i| all_calls[i] == calls_to_find[0] }
    positions.any? do |position|
      test_array = all_calls.slice(position, calls_to_find.length)
      test_array & calls_to_find == calls_to_find
    end
  end

  describe "with a request for a PDF gantt" do
    it "contains correct data" do
      expect(pdf[:strings]).to eq [query.name, "2024 Apr 21 22 23", # header columns
                                   wp_title_column(work_package_task),
                                   wp_title_column(work_package_milestone),
                                   "1/1", export_time_formatted, query.name].join(" ").squeeze(" ")

      # if one of these expect fails you can output the actual pdf calls uncommenting the following line
      # show_calls
      milestone = [
        [:set_color_for_nonstroking_and_special, 1.0, 0.0, 0.0], # red milestone polygon
        [:begin_new_subpath, 627.83333, 401.86],
        [:append_line, 634.5, 408.52667],
        [:append_line, 641.16667, 401.86],
        [:append_line, 634.5, 395.19333],
        [:append_line, 627.83333, 401.86],
        [:close_subpath]
      ]
      expect(include_calls?(milestone, pdf[:calls])).to be true
      task = [
        [:set_color_for_nonstroking_and_special, 1.0, 1.0, 0.0], # yellow rectangle
        [:append_rectangle, 207.0, 416.86, 171.0, 10.0],
        [:fill_path_with_nonzero]
      ]
      expect(include_calls?(task, pdf[:calls])).to be true
    end
  end

  describe "with a request for a PDF gantt split on multiple horizontal pages" do
    let(:work_package_milestone_due) do
      Date.new(2024, 5, 8)
    end

    it "contains correct data" do
      expect(pdf[:strings]).to eq [query.name, "2024 Apr May 21 22 23 24 25 26 27 28 29 30 1 2 3 4 5", # header columns
                                   wp_title_column(work_package_task),
                                   wp_title_column(work_package_milestone),
                                   "1/2", export_time_formatted, query.name,
                                   "2024 May 6 7 8", # header columns
                                   "2/2", export_time_formatted, query.name].join(" ").squeeze(" ")

      # if one of these expect fails you can output the actual pdf calls uncommenting the following line
      # show_calls
      milestone = [
        [:set_color_for_nonstroking_and_special, 1.0, 0.0, 0.0], # red milestone polygon
        [:begin_new_subpath, 110.7619, 390.0],
        [:append_line, 117.42857, 396.66667],
        [:append_line, 124.09524, 390.0],
        [:append_line, 117.42857, 383.33333],
        [:append_line, 110.7619, 390.0],
        [:close_subpath]
      ]
      expect(include_calls?(milestone, pdf[:calls])).to be true
      task = [
        [:set_color_for_nonstroking_and_special, 1.0, 1.0, 0.0], # yellow rectangle
        [:append_rectangle, 231.42857, 405.0, 32.57143, 10.0],
        [:fill_path_with_nonzero]
      ]
      expect(include_calls?(task, pdf[:calls])).to be true
    end
  end

  describe "with a request for a PDF gantt split on multiple horizontal and vertical pages" do
    let(:work_packages) do
      [work_package_task] + filler_work_packages + [work_package_milestone]
    end
    let(:work_package_milestone_due) do
      Date.new(2024, 5, 8)
    end
    let(:large_example_content) do
      [
        query.name, "2024 Apr May 21 22 23 24 25 26 27 28 29 30 1 2 3 4 5", # header columns
        wp_title_column(work_package_task),
        filler_work_packages.slice(0, 17).map.map { |wp| wp_title_column(wp) },
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
      ].flatten.join(" ").squeeze(" ")
    end

    it "contains correct data" do
      expect(pdf[:strings]).to eq large_example_content

      # if one of these expect fails you can output the actual pdf calls uncommenting the following line
      # show_calls
      milestone = [
        [:set_color_for_nonstroking_and_special, 1.0, 0.0, 0.0], # red milestone polygon
        [:begin_new_subpath, 110.7619, 110.0],
        [:append_line, 117.42857, 116.66667],
        [:append_line, 124.09524, 110.0],
        [:append_line, 117.42857, 103.33333],
        [:append_line, 110.7619, 110.0],
        [:close_subpath]
      ]
      expect(include_calls?(milestone, pdf[:calls])).to be true
      task = [
        [:set_color_for_nonstroking_and_special, 1.0, 1.0, 0.0], # yellow rectangle
        [:append_rectangle, 231.42857, 405.0, 32.57143, 10.0],
        [:fill_path_with_nonzero]
      ]
      expect(include_calls?(task, pdf[:calls])).to be true
      expect(
        pdf[:calls].count { |call| call == [:set_color_for_nonstroking_and_special, 0.0, 1.0, 1.0] } # aqua color rectangles
      ).to be filler_work_packages.length
    end
  end

  describe "with a request for a PDF gantt split on multiple vertical pages" do
    let(:work_packages) do
      [work_package_task] + filler_work_packages + [work_package_milestone]
    end
    let(:work_package_milestone_due) do
      Date.new(2024, 5, 1)
    end
    let(:large_example_content) do
      [
        query.name, "2024 Apr May 21 22 23 24 25 26 27 28 29 30 1", # header columns
        wp_title_column(work_package_task),
        filler_work_packages.slice(0, 17).map { |wp| wp_title_column(wp) },
        "1/3", export_time_formatted, query.name,

        query.name, "2024 Apr May 21 22 23 24 25 26 27 28 29 30 1", # header columns
        filler_work_packages.slice(17, 18).map { |wp| wp_title_column(wp) },
        "2/3", export_time_formatted, query.name,

        query.name, "2024 Apr May 21 22 23 24 25 26 27 28 29 30 1", # header columns
        filler_work_packages.slice(35, 15).map { |wp| wp_title_column(wp) },
        wp_title_column(work_package_milestone),
        "3/3", export_time_formatted, query.name
      ].flatten.join(" ").squeeze(" ")
    end

    it "contains correct data" do
      expect(pdf[:strings]).to eq large_example_content

      # if one of these expect fails you can output the actual pdf calls uncommenting the following line
      # show_calls
      milestone = [
        [:set_color_for_nonstroking_and_special, 1.0, 0.0, 0.0], # red milestone polygon
        [:begin_new_subpath, 690.01515, 121.86],
        [:append_line, 696.68182, 128.52667],
        [:append_line, 703.34848, 121.86],
        [:append_line, 696.68182, 115.19333],
        [:append_line, 690.01515, 121.86],
        [:close_subpath]
      ]
      expect(include_calls?(milestone, pdf[:calls])).to be true
      task = [
        [:set_color_for_nonstroking_and_special, 1.0, 1.0, 0.0], # yellow rectangle
        [:append_rectangle, 207.0, 416.86, 46.63636, 10.0],
        [:fill_path_with_nonzero]
      ]
      expect(include_calls?(task, pdf[:calls])).to be true
      expect(
        pdf[:calls].count { |call| call == [:set_color_for_nonstroking_and_special, 0.0, 1.0, 1.0] } # aqua color rectangles
      ).to be filler_work_packages.length
    end
  end

  describe "with a request for a PDF gantt with grouped work packages" do
    let(:query_attributes) { { group_by: "type" } }

    it "contains correct data" do
      expect(pdf[:strings]).to eq [query.name, "2024 Apr 21 22 23", # header columns
                                   type_milestone.name,
                                   wp_title_column(work_package_milestone),
                                   type_standard.name,
                                   wp_title_column(work_package_task),
                                   "1/1", export_time_formatted, query.name].join(" ").squeeze(" ")

      # if one of these expect fails you can output the actual pdf calls uncommenting the following line
      # show_calls
      milestone = [
        [:set_color_for_nonstroking_and_special, 1.0, 0.0, 0.0], # red milestone polygon
        [:begin_new_subpath, 627.83333, 401.86],
        [:append_line, 634.5, 408.52667],
        [:append_line, 641.16667, 401.86],
        [:append_line, 634.5, 395.19333],
        [:append_line, 627.83333, 401.86],
        [:close_subpath]
      ]
      expect(include_calls?(milestone, pdf[:calls])).to be true
      task = [
        [:set_color_for_nonstroking_and_special, 1.0, 1.0, 0.0], # yellow rectangle
        [:append_rectangle, 207.0, 356.86, 171.0, 10.0],
        [:fill_path_with_nonzero]
      ]
      expect(include_calls?(task, pdf[:calls])).to be true
    end
  end
end
