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

require "rails_helper"

RSpec.describe OpPrimer::BorderBoxTableComponent, :aggregate_failures, type: :component do
  def render_component(**args)
    render_inline(table_class.new(**args))
  end

  let(:row_class) do
    Class.new(OpPrimer::BorderBoxRowComponent) do
      delegate :name, :description, to: :model

      def button_links
        ['<a href="">Example Link</a>'.html_safe]
      end
    end
  end

  let(:table_class) do
    Class.new(described_class) do
      columns :name, :description
      mobile_columns :name
      mobile_labels :name
      main_column :name

      def row_class
        TestBorderBoxRowComponent
      end

      def mobile_title
        "Mobile Header"
      end

      def headers
        [
          [:name, { caption: "Name" }],
          [:description, { caption: "Description" }]
        ]
      end

      def blank_title
        "No results"
      end

      def blank_description
        "Sorry, no results found."
      end

      def blank_icon
        :key
      end

      def has_actions?
        true
      end

      def has_footer?
        true
      end

      def footer
        "Footer content"
      end
    end
  end

  before do
    stub_const("TestBorderBoxComponent", table_class)
    stub_const("TestBorderBoxRowComponent", row_class)
  end

  subject(:rendered_component) { render_component(rows:) }

  shared_examples_for "rendering table with head and foot" do
    it "adds table semantics with colcount" do
      expect(rendered_component).to have_selector :role, :table, aria: { colcount: 3 }
    end

    it "provides an accessible name based on mobile title" do
      expect(rendered_component).to have_selector :role, :table, accessible_name: "Mobile Header"
    end

    it "adds rowgroup, row semantics for table head" do
      expect(render_component).to have_selector :role, :rowgroup, class: "Box-header" do |rowgroup|
        expect(rowgroup).to have_selector :row, count: 2
        expect(rowgroup).to have_selector :row, class: "op-border-box-grid--has-mobile-header"
        expect(rowgroup).to have_selector :row, class: "op-border-box-grid--has-headers"
      end
    end

    it "indexes both header rows as the first row" do
      expect(rendered_component).to have_selector :row, class: "op-border-box-grid--has-mobile-header", rowindex: 1
      expect(rendered_component).to have_selector :row, class: "op-border-box-grid--has-headers", rowindex: 1
    end

    context "for desktop" do
      it "renders column headers with explicit colindex" do
        expect(rendered_component).to have_selector :columnheader, count: 2, class: "op-border-box-grid__header"
        expect(rendered_component).to have_selector :columnheader, count: 1, class: "op-border-box-grid__header-action"

        expect(rendered_component).to have_selector :columnheader,
                                                    text: "Name",
                                                    class: "op-border-box-grid__header",
                                                    aria: { colindex: 1 }
        expect(rendered_component).to have_selector :columnheader,
                                                    text: "Description",
                                                    class: "op-border-box-grid__header",
                                                    aria: { colindex: 2 }
        expect(rendered_component).to have_selector :columnheader,
                                                    accessible_name: "Actions",
                                                    class: "op-border-box-grid__header-action",
                                                    aria: { colindex: 3 }
      end
    end

    context "for mobile" do
      it "renders column header with colspan" do
        expect(rendered_component).to have_selector :columnheader, count: 1, class: "op-border-box-grid__mobile-header"
        expect(rendered_component).to have_selector :columnheader,
                                                    text: "Mobile Header",
                                                    class: "op-border-box-grid__mobile-header",
                                                    aria: { colspan: 3 }
      end
    end

    it "adds rowgroup, row and cell semantics for table foot" do
      expect(rendered_component).to have_selector :role, :rowgroup, class: "Box-footer" do |rowgroup|
        expect(rowgroup).to have_selector :row, count: 1 do |row|
          expect(row).to have_selector :role, :cell, count: 1, aria: { colspan: 3 }
        end
      end
    end
  end

  shared_examples_for "indexing rows" do |rowcount:, first:, last:, footer: true|
    it "sets the row count on the table" do
      expect(rendered_component).to have_selector :role, :table, aria: { rowcount: }
    end

    it "indexes body rows consecutively from #{first}" do
      expect(rendered_component).to have_selector :role, :rowgroup, class: "!Box-header" do |rowgroup|
        (first..last).each do |index|
          expect(rowgroup).to have_selector :row, rowindex: index
        end
        expect(rowgroup).to have_no_selector :row, rowindex: first - 1
        expect(rowgroup).to have_no_selector :row, rowindex: last + 1
      end
    end

    if footer
      it "indexes the footer row as the last row" do
        expect(rendered_component).to have_selector :role, :rowgroup, class: "Box-footer" do |rowgroup|
          expect(rowgroup).to have_selector :row, rowindex: rowcount
        end
      end
    end
  end

  context "with no rows" do
    let(:rows) { build_stubbed_list(:project, 0) }

    it_behaves_like "rendering table with head and foot"

    it "adds rowgroup, row and cell semantics for table body" do
      expect(rendered_component).to have_selector :role, :rowgroup, class: "!Box-header" do |rowgroup|
        expect(rowgroup).to have_selector :row, count: 1 do |row|
          expect(row).to have_selector :role, :cell, count: 1, aria: { colspan: 3 }
        end
      end
    end

    it_behaves_like "rendering Blank Slate", heading: "No results"

    it_behaves_like "indexing rows", rowcount: 3, first: 2, last: 2
  end

  context "with rows" do
    let(:rows) { build_stubbed_list(:project, 3) }

    it_behaves_like "rendering table with head and foot"

    it "adds rowgroup, row semantics for table body" do
      expect(rendered_component).to have_selector :role, :rowgroup, class: "!Box-header" do |rowgroup|
        expect(rowgroup).to have_selector :row, count: 3
      end
    end

    it "adds cell semantics" do
      expect(rendered_component).to have_selector :row, class: "Box-row" do |row|
        expect(row).to have_selector :role, :rowheader, count: 1, class: "op-border-box-grid__row-item"
        expect(row).to have_selector :role, :cell, count: 1, class: "op-border-box-grid__row-item"
        expect(row).to have_selector :role, :cell, count: 1, class: "op-border-box-grid__row-action"
      end
    end

    it_behaves_like "indexing rows", rowcount: 5, first: 2, last: 4

    it "indexes rows in rendering order" do
      rows.each.with_index(2) do |project, index|
        expect(rendered_component).to have_selector :row, project.name, rowindex: index
      end
    end
  end

  context "with rows and no footer" do
    let(:rows) { build_stubbed_list(:project, 3) }

    before do
      table_class.define_method(:has_footer?) { false }
    end

    it "renders no footer row, keeping the columns" do
      expect(rendered_component).to have_selector :role, :table, aria: { colcount: 3 }
      expect(rendered_component).to have_no_selector :role, :rowgroup, class: "Box-footer"
    end

    it_behaves_like "indexing rows", rowcount: 4, first: 2, last: 4, footer: false
  end

  context "with a page of a paginated collection" do
    let(:rows) do
      WillPaginate::Collection.create(2, 3, 10) do |pager|
        pager.replace(build_stubbed_list(:project, 3))
      end
    end

    subject(:rendered_component) do
      with_request_url("/projects") { render_component(rows:) }
    end

    it_behaves_like "rendering table with head and foot"

    it_behaves_like "indexing rows", rowcount: 12, first: 5, last: 7
  end
end
