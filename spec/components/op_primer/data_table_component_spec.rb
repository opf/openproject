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

RSpec.describe OpPrimer::DataTableComponent, type: :component do
  let(:statuses) { create_list(:status, 2) }

  # A concrete generic table, mirroring how real callers subclass the shim.
  before do
    stub_const("PocStatuses::TableComponent", Class.new(described_class) do
      def self.name = "PocStatuses::TableComponent"

      def sortable? = false

      def row_class = Statuses::RowComponent

      def headers
        [
          [:name, { caption: "Name" }],
          [:done_ratio, { caption: "Progress" }]
        ]
      end

      def columns = headers.map(&:first)
    end)
  end

  subject(:rendered_component) { render_inline(PocStatuses::TableComponent.new(rows: statuses)) }

  it "renders a DataTable rather than a legacy table" do
    expect(rendered_component).to have_css(".TableContainer .Table")
    expect(rendered_component).to have_no_table(class: "generic-table")
  end

  it "renders one header per declared column plus the actions header" do
    expect(rendered_component).to have_css(".TableHead .TableHeader", count: 3)
    expect(rendered_component).to have_text("Name")
    expect(rendered_component).to have_text("Progress")
  end

  it "renders one row per record" do
    expect(rendered_component).to have_css(".TableBody .TableRow", count: 2)
  end

  it "renders each row's cell contents through its RowComponent" do
    expect(rendered_component).to have_link(statuses.first.name)
  end

  it "renders the action links in a trailing cell" do
    expect(rendered_component)
      .to have_css(".TableRow .TableCell.op-data-table--actions-column a[data-turbo-method='delete']")
  end

  it "wraps the table so Turbo streams can target it" do
    expect(rendered_component).to have_css("#poc-statuses-table-component")
  end

  context "with no rows" do
    let(:statuses) { [] }

    it "renders the empty state from empty_row_message" do
      expect(rendered_component).to have_text(I18n.t(:no_results_title_text))
      expect(rendered_component).to have_no_css(".TableBody .TableRow")
    end
  end

  describe "sorting and pagination" do
    let!(:statuses) { create_list(:status, 3) }

    before do
      stub_const("PocSorted::TableComponent", Class.new(described_class) do
        def self.name = "PocSorted::TableComponent"

        columns :name, :done_ratio
        sortable_columns :name, :done_ratio

        def row_class = Statuses::RowComponent

        def initial_sort = %i[name asc]

        def headers
          [
            [:name, { caption: "Name" }],
            [:done_ratio, { caption: "Progress", default_order: "desc" }]
          ]
        end
      end)
    end

    def render_table(url, component_class: PocSorted::TableComponent, rows: Status.all)
      with_request_url(url) do
        allow(vc_test_controller).to receive_messages(controller_name: "statuses", action_name: "index")

        render_inline(component_class.new(rows:))
      end
    end

    it "renders sortable headers as links, not client-sort buttons" do
      rendered = render_table("/statuses")

      expect(rendered).to have_css("th a[href*='sort=']")
      expect(rendered).to have_css("[data-external-sorting]")
    end

    it "builds sort links through SortHelper, preserving other params" do
      rendered = render_table("/statuses?per_page=25")

      expect(rendered).to have_css("a[href*='per_page=25']")
    end

    it "omits the page param from sort links so sorting resets pagination" do
      rendered = render_table("/statuses?page=1")

      expect(rendered).to have_no_css("th a[href*='page=1']")
    end

    it "requests descending first for a column defaulting to desc" do
      rendered = render_table("/statuses")

      expect(rendered).to have_css("a[href*='done_ratio%3Adesc']")
    end

    it "inverts the direction of the currently sorted column" do
      rendered = render_table("/statuses?sort=name:asc")

      expect(rendered).to have_css("a[href*='name%3Adesc']")
    end

    it "marks an ascending sorted column with aria-sort" do
      rendered = render_table("/statuses?sort=name:asc")

      expect(rendered).to have_css("th[aria-sort='ascending']")
    end

    it "marks a descending sorted column with aria-sort" do
      rendered = render_table("/statuses?sort=name:desc")

      expect(rendered).to have_css("th[aria-sort='descending']")
    end

    it "renders a pagination footer for a populated collection" do
      rendered = render_table("/statuses")

      expect(rendered).to have_css(".TablePagination")
    end

    it "renders no pagination footer when the collection is empty" do
      rendered = render_table(
        "/statuses",
        rows: Status.where(id: -1)
      )

      expect(rendered).to have_no_css(".TablePagination")
    end
  end

  describe "column pairing" do
    it "raises when headers and columns disagree in size" do
      stub_const("PocMismatch::TableComponent", Class.new(described_class) do
        def self.name = "PocMismatch::TableComponent"

        def sortable? = false

        def row_class = Statuses::RowComponent

        def columns = %i[name done_ratio]

        def headers = [[:name, { caption: "Name" }]]
      end)

      expect { render_inline(PocMismatch::TableComponent.new(rows: [])) }
        .to raise_error(ArgumentError, /headers \(1\) and columns \(2\) must correspond/)
    end
  end
end
