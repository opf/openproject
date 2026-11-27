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
  # Sequenced position on purpose: the grouped export orders by it, and the named type
  # factories hard-code low positions that would sort them before the milestone type.
  let(:type_task) { create(:type, name: "Task", color: create(:color, hexcode: "#FFFF00")) }
  let(:type_bug) { create(:type_bug, name: "Bug", color: create(:color, hexcode: "#00FFFF")) }
  let!(:type_milestone) { create(:type, name: "Milestone", is_milestone: true, color: create(:color, hexcode: "#FF0000")) }
  let(:types) { [type_task, type_milestone] }
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
  let(:export_date_formatted) { format_date(export_time) }
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
  let(:work_package_task_due_too_long) do
    work_package_task_due + (Exports::PDF::Components::Gantt::GanttBuilder::MAX_YEAR_RANGE + 1).years
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
           type: type_task,
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
  let(:work_package_task_far_future) do
    create(:work_package,
           project:,
           status: status_new,
           type: type_task,
           subject: "Work package 3",
           start_date: work_package_task_start,
           due_date: work_package_task_due_too_long)
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
  let(:rows_per_page) { 15 }

  def show_pdf
    cmd = "open -a Preview #{export_pdf.content.path}"
    `#{cmd}`
  end

  def show_calls
    pp pdf[:calls]
  end

  def text_column_captions
    %i[id subject start_date due_date].map { |name| WorkPackage.human_attribute_name(name) }
  end

  def wp_text_cells(work_package)
    [work_package.display_id, work_package.subject,
     format_date(work_package.start_date), format_date(work_package.due_date)].compact.join(" ")
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
      expect(pdf[:strings]).to eq [text_column_captions, "2024 Apr 21 22 23", # header columns
                                   wp_text_cells(work_package_task),
                                   wp_text_cells(work_package_milestone),
                                   "1/1", export_date_formatted, query.name].join(" ").squeeze(" ")

      # if one of these expect fails you can output the actual pdf calls uncommenting the following line
      # show_calls
      milestone = [
        [:set_color_for_nonstroking_and_special, 1.0, 0.0, 0.0], # red milestone polygon
        [:begin_new_subpath, 697.04762, 395.86],
        [:append_line, 703.71429, 402.52667],
        [:append_line, 710.38095, 395.86],
        [:append_line, 703.71429, 389.19333],
        [:append_line, 697.04762, 395.86],
        [:close_subpath]
      ]
      expect(include_calls?(milestone, pdf[:calls])).to be true
      task = [
        [:set_color_for_nonstroking_and_special, 1.0, 1.0, 0.0], # yellow rectangle
        [:append_rectangle, 622.28571, 414.86, 32.57143, 10.0],
        [:fill_path_with_nonzero]
      ]
      expect(include_calls?(task, pdf[:calls])).to be true
    end
  end

  describe "work package id formatting" do
    context "in classic mode",
            with_settings: { work_packages_identifier: "classic" } do
      it "uses the numeric id and not the semantic identifier in the gantt chart" do
        expect(pdf[:strings]).to include("#{work_package_task.id} #{work_package_task.subject}")
      end
    end

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      it "uses the semantic identifier and not the numeric id in the gantt chart" do
        expect(pdf[:strings]).to include("#{work_package_task.identifier} #{work_package_task.subject}")
        expect(pdf[:strings]).not_to include("#{work_package_task.id} #{work_package_task.subject}")
      end
    end
  end

  describe "with a request for a PDF gantt split on multiple horizontal pages" do
    let(:work_package_milestone_due) do
      Date.new(2024, 5, 8)
    end

    it "contains correct data" do
      expect(pdf[:strings]).to eq [text_column_captions, "2024 Apr May 21 22 23 24 25 26 27 28 29 30 1 2 3 4", # header columns
                                   wp_text_cells(work_package_task),
                                   wp_text_cells(work_package_milestone),
                                   "1/2", export_date_formatted, query.name,
                                   "2024 May 5 6 7 8", # header columns
                                   "2/2", export_date_formatted, query.name].join(" ").squeeze(" ")

      # if one of these expect fails you can output the actual pdf calls uncommenting the following line
      # show_calls
      milestone = [
        [:set_color_for_nonstroking_and_special, 1.0, 0.0, 0.0], # red milestone polygon
        [:begin_new_subpath, 143.33333, 384.0],
        [:append_line, 150.0, 390.66667],
        [:append_line, 156.66667, 384.0],
        [:append_line, 150.0, 377.33333],
        [:append_line, 143.33333, 384.0],
        [:close_subpath]
      ]
      expect(include_calls?(milestone, pdf[:calls])).to be true
      task = [
        [:set_color_for_nonstroking_and_special, 1.0, 1.0, 0.0], # yellow rectangle
        [:append_rectangle, 231.976, 403.0, 32.57143, 10.0],
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
      row_pages = [work_package_task, *filler_work_packages, work_package_milestone]
                    .map { |wp| wp_text_cells(wp) }
                    .each_slice(rows_per_page).to_a
      page_count = row_pages.size * 2
      row_pages.each_with_index.flat_map do |rows, index|
        [text_column_captions, "2024 Apr May 21 22 23 24 25 26 27 28 29 30 1 2 3 4", # header columns
         rows,
         "#{(index * 2) + 1}/#{page_count}", export_date_formatted, query.name,
         "2024 May 5 6 7 8", # header columns
         "#{(index * 2) + 2}/#{page_count}", export_date_formatted, query.name]
      end.flatten.join(" ").squeeze(" ")
    end

    it "contains correct data" do
      expect(pdf[:strings]).to eq large_example_content

      # if one of these expect fails you can output the actual pdf calls uncommenting the following line
      # show_calls
      milestone = [
        [:set_color_for_nonstroking_and_special, 1.0, 0.0, 0.0], # red milestone polygon
        [:begin_new_subpath, 143.33333, 264.0],
        [:append_line, 150.0, 270.66667],
        [:append_line, 156.66667, 264.0],
        [:append_line, 150.0, 257.33333],
        [:append_line, 143.33333, 264.0],
        [:close_subpath]
      ]
      expect(include_calls?(milestone, pdf[:calls])).to be true
      task = [
        [:set_color_for_nonstroking_and_special, 1.0, 1.0, 0.0], # yellow rectangle
        [:append_rectangle, 245.536, 403.0, 32.57143, 10.0],
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
      row_pages = [work_package_task, *filler_work_packages, work_package_milestone]
                    .map { |wp| wp_text_cells(wp) }
                    .each_slice(rows_per_page).to_a
      row_pages.each_with_index.flat_map do |rows, index|
        [text_column_captions, "2024 Apr May 21 22 23 24 25 26 27 28 29 30 1", # header columns
         rows,
         "#{index + 1}/#{row_pages.size}", export_date_formatted, query.name]
      end.flatten.join(" ").squeeze(" ")
    end

    it "contains correct data" do
      expect(pdf[:strings]).to eq large_example_content

      # if one of these expect fails you can output the actual pdf calls uncommenting the following line
      # show_calls
      milestone = [
        [:set_color_for_nonstroking_and_special, 1.0, 0.0, 0.0], # red milestone polygon
        [:begin_new_subpath, 697.04762, 275.86],
        [:append_line, 703.71429, 282.52667],
        [:append_line, 710.38095, 275.86],
        [:append_line, 703.71429, 269.19333],
        [:append_line, 697.04762, 275.86],
        [:close_subpath]
      ]
      expect(include_calls?(milestone, pdf[:calls])).to be true
      task = [
        [:set_color_for_nonstroking_and_special, 1.0, 1.0, 0.0], # yellow rectangle
        [:append_rectangle, 361.71429, 414.86, 32.57143, 10.0],
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
      expect(pdf[:strings]).to eq [text_column_captions, "2024 Apr 21 22 23", # header columns
                                   type_milestone.name,
                                   wp_text_cells(work_package_milestone),
                                   type_task.name,
                                   wp_text_cells(work_package_task),
                                   "1/1", export_date_formatted, query.name].join(" ").squeeze(" ")

      # if one of these expect fails you can output the actual pdf calls uncommenting the following line
      # show_calls
      milestone = [
        [:set_color_for_nonstroking_and_special, 1.0, 0.0, 0.0], # red milestone polygon
        [:begin_new_subpath, 697.04762, 395.86],
        [:append_line, 703.71429, 402.52667],
        [:append_line, 710.38095, 395.86],
        [:append_line, 703.71429, 389.19333],
        [:append_line, 697.04762, 395.86],
        [:close_subpath]
      ]
      expect(include_calls?(milestone, pdf[:calls])).to be true
      task = [
        [:set_color_for_nonstroking_and_special, 1.0, 1.0, 0.0], # yellow rectangle
        [:append_rectangle, 622.28571, 342.86, 32.57143, 10.0],
        [:fill_path_with_nonzero]
      ]
      expect(include_calls?(task, pdf[:calls])).to be true
    end
  end

  describe "with a request for a PDF gantt grouped by target versions" do
    let(:query_attributes) { { group_by: "target_versions" } }
    let(:version_one) { create(:version, project:, name: "1.0") }
    let(:version_two) { create(:version, project:, name: "2.0") }
    let(:work_packages) do
      work_package_task.target_version_ids_replacements = [version_one.id, version_two.id]
      work_package_task.save!
      [work_package_task, work_package_milestone]
    end

    context "with multiple versions active",
            with_settings: { work_package_multiple_versions: true } do
      it "joins the several target versions of a work package into one group, " \
         "and groups work packages without a target version under a none placeholder" do
        expect(pdf[:strings]).to eq [text_column_captions, "2024 Apr 21 22 23", # header columns
                                     "1.0, 2.0",
                                     wp_text_cells(work_package_task),
                                     I18n.t(:label_none_parentheses),
                                     wp_text_cells(work_package_milestone),
                                     "1/1", export_date_formatted, query.name].join(" ").squeeze(" ")
      end
    end

    context "with multiple versions inactive",
            with_settings: { work_package_multiple_versions: false } do
      let(:query_attributes) { { group_by: "version" } }
      let(:version_one) { create(:version, project:, name: "2.0") }
      let(:version_two) { create(:version, project:, name: "1.0") }

      it "groups a work package under its lowest-id target version, " \
         "and groups work packages without a target version under a none placeholder" do
        expect(pdf[:strings]).to eq [text_column_captions, "2024 Apr 21 22 23", # header columns
                                     version_one.name,
                                     wp_text_cells(work_package_task),
                                     I18n.t(:label_none_parentheses),
                                     wp_text_cells(work_package_milestone),
                                     "1/1", export_date_formatted, query.name].join(" ").squeeze(" ")
      end
    end
  end

  describe "text column selection" do
    let(:column_names) { %w[status priority] }
    let(:text_column_names) { export.column_objects.map { |column| column.name.to_s } }

    it "uses ID, subject, start date and finish date when no columns are requested" do
      expect(text_column_names).to eq(%w[id subject start_date due_date])
    end

    context "with requested columns" do
      let(:options) { super().merge(columns: %w[due_date subject type status priority start_date id]) }

      it "uses them in order, capped at the maximum column count" do
        expect(text_column_names).to eq(%w[due_date subject type status priority start_date])
      end
    end

    context "with disallowed and unknown columns requested" do
      let(:options) { super().merge(columns: %w[relations_of_type_follows unknown subject]) }

      it "drops them" do
        expect(text_column_names).to eq(%w[subject])
      end
    end

    context "with an empty selection" do
      let(:options) { super().merge(columns: [""], no_columns: "1") }

      it "falls back to the subject" do
        expect(text_column_names).to eq(%w[subject])
      end
    end

    context "with no_columns but without a columns parameter" do
      let(:options) { super().merge(no_columns: "1") }

      it "falls back to the subject" do
        expect(text_column_names).to eq(%w[subject])
      end
    end

    it "passes the resolved columns to the gantt builder" do
      builder = nil
      allow(Exports::PDF::Components::Gantt::GanttBuilderDays).to receive(:new).and_wrap_original do |method, *args|
        builder = method.call(*args)
        allow(builder).to receive(:build).and_call_original
        builder
      end

      export_pdf

      expect(builder).to have_received(:build)
        .with(anything, anything, query, export.column_objects, cell_value: anything)
    end
  end

  describe "text cells" do
    let(:raw_strings) { PDF::Inspector::Text.analyze(File.read(export_pdf.content.path)).strings }

    context "with a subject longer than two lines" do
      let(:long_subject) { "Lorem ipsum dolor sit amet " * 30 }

      before { work_package_task.update!(subject: long_subject) }

      it "wraps it onto two lines and ellipsizes the second" do
        subject_lines = raw_strings.select { |text| text.start_with?("Lorem", "ipsum", "dolor", "sit", "amet") }

        expect(subject_lines.size).to eq(2)
        expect(subject_lines.last).to end_with("...")
        expect(pdf[:strings]).not_to include(long_subject.strip)
      end
    end

    it "renders short values on a single line" do
      expect(raw_strings).to include(work_package_task.subject)
    end

    context "with grouped work packages and a narrow text area" do
      let(:query_attributes) { { group_by: "type" } }
      let(:options) { super().merge(columns: %w[id]) }
      let(:type_task) { create(:type, name: "A type name far wider than the identifier column") }

      it "lets the group title run on into the chart area over a blank background" do
        expect(raw_strings).to include(type_task.name)
        expect(pdf[:calls]).to include([:set_color_for_nonstroking_and_special, 1.0, 1.0, 1.0])
      end

      context "when the group title is wider than the page" do
        let(:type_task) { create(:type, name: ("Very long type name " * 12).strip) }

        it "ellipsizes it at the page edge" do
          title = raw_strings.find { |text| text.start_with?("Very long type name") }

          expect(title).to end_with("...")
          expect(title.length).to be < type_task.name.length
        end
      end
    end

    it "shows the column captions in the header and the view name only in the footer" do
      expect(pdf[:strings]).to start_with(text_column_captions.join(" "))
      expect(raw_strings.count(query.name)).to eq(1)
    end

    context "with a column caption longer than two lines" do
      let(:long_name) { "A custom field with a remarkably long name that cannot fit into its column" }
      let(:custom_field) { create(:string_wp_custom_field, name: long_name, is_for_all: true, types:) }
      let(:options) { super().merge(columns: ["subject", custom_field.column_name]) }

      it "wraps it onto two lines and ellipsizes the second" do
        subject_caption, *custom_field_caption = raw_strings.take_while { |text| text != "2024" }

        expect(subject_caption).to eq(WorkPackage.human_attribute_name(:subject))
        expect(custom_field_caption.size).to eq(2)
        expect(custom_field_caption.first).to start_with("A custom field")
        expect(custom_field_caption.last).to end_with("...")
      end
    end

    describe "#gantt_text_cell_value" do
      let(:id_column) { Queries::WorkPackages::Selects::PropertySelect.new(:id) }
      let(:spent_hours_column) { Queries::WorkPackages::Selects::PropertySelect.new(:spent_hours) }

      it "uses the display id for the ID column" do
        expect(export.gantt_text_cell_value(work_package_task, id_column)).to eq(work_package_task.display_id)
      end

      it "hides attributes the user may not view" do
        allow(export).to receive(:allowed_to_view_attribute?).and_call_original
        allow(export).to receive(:allowed_to_view_attribute?)
          .with(work_package_task, :spent_hours).and_return(false)

        expect(export.gantt_text_cell_value(work_package_task, spent_hours_column)).to eq("")
      end
    end
  end

  describe "work packages without dates" do
    let(:work_package_without_dates) do
      create(:work_package, project:, status: status_new, type: type_task,
                            subject: "Work package without dates", start_date: nil, due_date: nil)
    end
    let(:work_packages) { [work_package_task, work_package_milestone, work_package_without_dates] }
    let(:bar_colors) do
      [[:set_color_for_nonstroking_and_special, 1.0, 1.0, 0.0], [:set_color_for_nonstroking_and_special, 1.0, 0.0, 0.0]]
    end

    it "leaves them out by default" do
      expect(pdf[:strings]).not_to include(work_package_without_dates.subject)
    end

    context "when they are included" do
      let(:options) { super().merge(gantt_include_without_dates: "true") }

      it "lists them with empty chart cells" do
        expect(pdf[:strings]).to eq [text_column_captions, "2024 Apr 21 22 23", # header columns
                                     wp_text_cells(work_package_task),
                                     wp_text_cells(work_package_milestone),
                                     wp_text_cells(work_package_without_dates),
                                     "1/1", export_date_formatted, query.name].join(" ").squeeze(" ")
        expect(pdf[:calls].count { |call| bar_colors.include?(call) }).to eq(2)
      end

      context "with a dependency to a work package without dates" do
        before do
          create(:relation, from: work_package_without_dates, to: work_package_task, relation_type: Relation::TYPE_FOLLOWS)
        end

        it "skips the dependency line" do
          expect(pdf[:strings]).to include(work_package_without_dates.subject)
        end
      end

      context "when no work package has dates" do
        let(:work_packages) { [work_package_without_dates] }
        let(:relation) { nil }

        it "exports only the text columns" do
          expect(pdf[:strings]).to eq [text_column_captions,
                                       wp_text_cells(work_package_without_dates),
                                       "1/1", export_date_formatted, query.name].join(" ").squeeze(" ")
          expect(pdf[:calls].count { |call| bar_colors.include?(call) }).to eq(0)
        end
      end
    end
  end

  describe "with a request for a PDF gantt with too long date range" do
    let(:work_packages) { [work_package_task_far_future] }

    it "raises as the date range is too long" do
      expect { export_pdf }.to raise_error(
        Exports::ExportError,
        I18n.t(
          :error_pdf_date_range_too_long,
          years: Exports::PDF::Components::Gantt::GanttBuilder::MAX_YEAR_RANGE
        )
      )
    end
  end
end
