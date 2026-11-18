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

RSpec.describe Exports::PDF::Components::Gantt::GanttBuilder do
  let(:paper_size) { "A4" }
  let(:pdf) { Prawn::Document.new(page_size: paper_size, page_layout: :landscape) }
  let(:builder_class) { Exports::PDF::Components::Gantt::GanttBuilderDays }
  let(:column_width) { 32 }
  let(:project) { create(:project) }
  let(:query) { build(:query, project:) }
  let(:column_names) { %i[id subject start_date due_date] }
  let(:query_columns) do
    property_columns = Queries::WorkPackages::Selects::PropertySelect.instances
    column_names.map { |name| property_columns.find { |column| column.name == name } }
  end
  let(:start_date) { Date.new(2024, 4, 1) }
  let(:days) { 60 }
  let(:row_count) { 2 }
  let(:work_packages) do
    Array.new(row_count) do |index|
      create(:work_package, project:, subject: "Work package #{index}",
                            start_date:, due_date: start_date + (days - 1))
    end
  end
  let(:cell_value) do
    ->(work_package, column) { Exports::Register.formatter_for(WorkPackage, column.name, :pdf).format(work_package) }
  end
  let(:pages) do
    builder_class.new(pdf, column_width).build(work_packages, {}, query, query_columns, cell_value:)
  end
  let(:page_width) { pdf.bounds.width }
  let(:first_pages) { pages.select { |page| page.index == 0 } }

  def text_area_width(page)
    page.columns.first.left
  end

  def date_column_widths(page_list)
    page_list.flat_map(&:columns).map { |column| column.width.round(5) }.uniq
  end

  context "when the chart needs several pages horizontally" do
    it "keeps the date column width identical on every page" do
      expect(pages.size).to be > 1
      expect(date_column_widths(pages).size).to eq(1)
    end

    it "sizes the text area by its content and leaves the remainder of page 0 blank" do
      page = first_pages.first

      expect(text_area_width(page)).to be < (page_width * 0.3)
      expect(page.width).to be <= page_width
      expect(page_width - page.width).to be < page.columns.first.width
    end

    context "with more rows than fit on one page" do
      let(:row_count) { 40 }

      it "gives every page group's first page the same text area" do
        expect(first_pages.size).to be > 1
        expect(first_pages.map { |page| text_area_width(page) }.uniq.size).to eq(1)
      end
    end
  end

  describe "text column header cells" do
    let(:row_count) { 40 }

    it "adds one header cell per text column on the first page of each page group only" do
      pages.each do |page|
        if page.index == 0
          expect(page.text_columns.map(&:caption)).to eq(query_columns.map(&:caption))
        else
          expect(page.text_columns).to be_empty
        end
      end
    end

    it "lays the header cells out side by side up to the first date column, spanning the header row" do
      page = first_pages.first
      header_cells = page.text_columns

      expect(header_cells.first.left).to eq(0.0)
      expect(header_cells.drop(1).map(&:left)).to eq(header_cells[0..-2].map(&:right))
      expect(header_cells.last.right).to be_within(0.001).of(text_area_width(page))
      expect(header_cells.map(&:height).uniq).to eq([page.header_row_height])
    end
  end

  context "when no work package has dates" do
    let(:work_packages) do
      Array.new(row_count) do |index|
        create(:work_package, project:, subject: "Work package #{index}", start_date: nil, due_date: nil)
      end
    end

    %w[GanttBuilderDays GanttBuilderWeeks GanttBuilderMonths GanttBuilderQuarters].each do |builder_name|
      context "with #{builder_name}" do
        let(:builder_class) { Exports::PDF::Components::Gantt.const_get(builder_name) }

        it "builds one page of text columns stretched to the page width, without date columns" do
          page = pages.first

          expect(pages.size).to eq(1)
          expect(page.columns).to be_empty
          expect(page.header_cells).to be_empty
          expect(page.text_columns.last.right).to be_within(0.001).of(page_width)
          expect(page.rows.map(&:shape)).to all(be_nil)
        end
      end
    end

    context "without a stretchable text column" do
      let(:column_names) { %i[id start_date due_date] }

      it "keeps the measured text column widths" do
        expect(pages.first.text_columns.last.right).to be < (page_width * 0.3)
      end
    end

    context "with more rows than fit on one page" do
      let(:row_count) { 40 }

      it "builds one page per page group" do
        expect(pages.size).to be > 1
        expect(pages.map(&:index).uniq).to eq([0])
      end
    end
  end

  describe "dependency lines" do
    let(:successor) do
      create(:work_package, project:, subject: "Successor", start_date:, due_date: start_date + 2)
    end
    let(:predecessor_start) { start_date + 5 }
    let(:predecessor) do
      create(:work_package, project:, subject: "Predecessor",
                            start_date: predecessor_start, due_date: predecessor_start + 1)
    end
    let(:fillers) do
      Array.new(filler_count) do |index|
        create(:work_package, project:, subject: "Filler #{index}", start_date:, due_date: start_date + (days - 1))
      end
    end
    let(:filler_count) { 0 }
    let(:work_packages) { [successor, *fillers, predecessor] }

    before { create(:relation, from: successor, to: predecessor, relation_type: Relation::TYPE_FOLLOWS) }

    def expect_no_line_in_text_area
      lines = first_pages.flat_map { |page| page.lines.map { |line| [page, line] } }

      expect(lines).not_to be_empty
      lines.each do |page, line|
        expect([line[:left], line[:right]].min).to be >= text_area_width(page) - 0.001
      end
    end

    context "when the target starts in the first date column of the same page" do
      it "keeps the lines out of the text area" do
        expect_no_line_in_text_area
      end
    end

    context "when the source is in a later page group and on a later horizontal page" do
      let(:filler_count) { 40 }
      let(:predecessor_start) { start_date + (days - 2) }

      it "keeps the lines out of the text area" do
        expect(pages.map(&:group).uniq.size).to be > 1
        expect_no_line_in_text_area
      end
    end
  end

  context "when the chart fits on one page" do
    let(:days) { 3 }

    it "keeps the date column width and stretches the first stretchable text column" do
      page = pages.first

      expect(pages.size).to eq(1)
      expect(page.width).to be_within(0.001).of(page_width)
      expect(page.columns.map(&:width).uniq.size).to eq(1)
      expect(page.columns.first.width).to be < 40
      expect(text_area_width(page)).to be > (page_width - (3 * 40))
    end

    context "without a stretchable text column" do
      let(:column_names) { %i[id start_date due_date] }

      it "stretches the date columns instead" do
        page = pages.first

        expect(page.width).to be_within(0.001).of(page_width)
        expect(text_area_width(page)).to be < (page_width * 0.3)
        expect(page.columns.first.width).to be > (page_width / 2 / 3)
      end
    end
  end

  paper_sizes = %w[A4 A3 EXECUTIVE]

  {
    "GanttBuilderDays" => 32,
    "GanttBuilderWeeks" => 64,
    "GanttBuilderMonths" => 128,
    "GanttBuilderQuarters" => 128
  }.each do |builder_name, width|
    paper_sizes.each do |size|
      context "with #{builder_name} on #{size}" do
        let(:builder_class) { Exports::PDF::Components::Gantt.const_get(builder_name) }
        let(:column_width) { width }
        let(:paper_size) { size }
        let(:days) { 800 }
        let(:column_names) { %i[id subject type status project] }

        it "keeps the text area within its limit and at least one date column on page 0" do
          page = first_pages.first

          expect(text_area_width(page)).to be <= (page_width * 0.6) + 0.001
          expect(page.columns).not_to be_empty
          expect(date_column_widths(pages).size).to eq(1)
        end
      end
    end
  end
end
