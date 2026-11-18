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

RSpec.describe Exports::PDF::Components::Gantt::GanttTextColumnLayout do
  subject(:layout) do
    described_class.new(pdf, query, query_columns, cell_value:, **layout_options).measure(work_packages)
  end

  let(:cell_value) do
    ->(work_package, column) { Exports::Register.formatter_for(WorkPackage, column.name, :pdf).format(work_package) }
  end

  let(:pdf) { Prawn::Document.new(page_layout: :landscape) }
  let(:layout_options) { {} }
  let(:query) { build_stubbed(:query) }
  let(:column_names) { %i[id subject start_date due_date] }
  let(:query_columns) do
    property_columns = Queries::WorkPackages::Selects::PropertySelect.instances
    column_names.map { |name| property_columns.find { |column| column.name == name } }
  end
  let(:subject_text) { "Short" }
  let(:work_packages) do
    [build_stubbed(:work_package, subject: subject_text, start_date: Date.new(2024, 4, 21), due_date: Date.new(2024, 4, 23))]
  end
  let(:page_width) { 720.0 }
  let(:date_column_width) { 32.0 }
  let(:min_width) { described_class::MIN_COLUMN_WIDTH }

  def widths
    layout.columns.map(&:width)
  end

  def width_of(name)
    layout.columns.find { |column| column.column.name == name }.width
  end

  before { layout.fit(page_width, date_column_width) }

  describe "#fit" do
    it "sizes the text area by its content, far below the page limit" do
      expect(layout.total_width).to be < (page_width * described_class::TEXT_AREA_MAX_RATIO / 2)
    end

    it "keeps every column at least at the minimum width" do
      expect(widths).to all(be >= min_width)
    end

    it "lays the columns out left to right" do
      lefts = layout.columns.map(&:left)
      rights = layout.columns.map(&:right)

      expect(lefts.first).to eq(0.0)
      expect(lefts.drop(1)).to eq(rights[0..-2])
      expect(rights.last).to be_within(0.001).of(layout.total_width)
    end

    context "with only one short column" do
      let(:column_names) { %i[id] }

      it "uses the minimum width" do
        expect(layout.total_width).to eq(min_width)
      end
    end

    context "with a very long subject" do
      let(:subject_text) { "A very long subject " * 20 }

      it "caps the subject at its max width" do
        expect(width_of(:subject)).to eq(described_class::MAX_WIDTHS[:subject])
      end
    end

    context "with a header caption wider than the values" do
      let(:column_names) { %i[remaining_hours] }
      let(:caption) { query_columns.first.caption }
      let(:full_caption_width) do
        pdf.width_of(caption, size: described_class::HEADER_FONT_SIZE, style: :bold) +
          (described_class::PADDING_H * 2)
      end

      it "measures the caption as wrapping onto two lines" do
        expect(width_of(:remaining_hours)).to be < full_caption_width
      end
    end

    context "when the natural widths exceed the page limit" do
      let(:column_names) { %i[id subject start_date due_date] }
      let(:subject_text) { "A very long subject " * 20 }
      let(:layout_options) { { max_area_ratio: 0.3 } }

      it "fits the text area into the page limit" do
        expect(layout.total_width).to be <= (page_width * 0.3) + 0.001
      end

      it "shrinks the subject before the fixed columns" do
        expect(width_of(:subject)).to be < described_class::MAX_WIDTHS[:subject]
        expect(width_of(:start_date)).to be > min_width
      end
    end

    context "when even the stretchable columns cannot absorb the excess" do
      let(:layout_options) { { max_area_ratio: 0.2 } }
      let(:subject_text) { "A very long subject " * 20 }

      it "also shrinks fixed columns, down to the minimum" do
        expect(layout.total_width).to be <= (page_width * 0.2) + 0.001
        expect(widths).to all(be >= min_width - 0.001)
      end
    end

    context "with a ratio larger than the page minus one date column" do
      let(:layout_options) { { max_area_ratio: 1.0 } }
      let(:subject_text) { "A very long subject " * 20 }
      let(:column_names) { %i[subject project assigned_to responsible author] }
      let(:page_width) { 400.0 }
      let(:date_column_width) { 128.0 }

      it "leaves room for at least one date column" do
        expect(layout.total_width).to be <= page_width - date_column_width + 0.001
      end
    end
  end

  describe "#stretch" do
    it "widens the first stretchable column and keeps the layout contiguous" do
      subject_width = width_of(:subject)

      expect(layout.stretch(100.0)).to be(true)
      expect(width_of(:subject)).to eq(subject_width + 100.0)
      expect(layout.columns.last.right).to be_within(0.001).of(layout.total_width)
    end

    context "without a stretchable column" do
      let(:column_names) { %i[id start_date due_date] }

      it "does nothing" do
        expect { expect(layout.stretch(100.0)).to be(false) }.not_to change(layout, :total_width)
      end
    end
  end

  describe "#value" do
    it "returns the PDF formatted value" do
      expect(layout.value(work_packages.first, query_columns.find { |c| c.name == :subject })).to eq("Short")
    end
  end
end
