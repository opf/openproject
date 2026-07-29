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

RSpec.describe OpPrimer::ResponsiveDataTableComponent, type: :component do
  let(:scim_clients) { create_list(:scim_client, 2) }

  before do
    stub_const("PocScim::TableComponent", Class.new(described_class) do
      def self.name = "PocScim::TableComponent"

      mobile_columns :name
      mobile_labels :created_at
      main_column :name

      def mobile_title = "SCIM clients"

      def row_class = Admin::ScimClients::RowComponent

      def headers
        [
          [:name, { caption: "Name" }],
          [:created_at, { caption: "Created on" }]
        ]
      end

      def columns = headers.map(&:first)

      def blank_title = "Nothing here"

      def blank_description = "Add one to get started"
    end)
  end

  subject(:rendered_component) { render_inline(PocScim::TableComponent.new(rows: scim_clients)) }

  it "renders a DataTable rather than a border box grid" do
    expect(rendered_component).to have_css(".TableContainer .Table")
    expect(rendered_component).to have_no_css(".op-border-box-grid")
  end

  it "scopes the responsive styles with a root class" do
    expect(rendered_component).to have_css(".Table.op-data-table--responsive")
  end

  it "renders the mobile title as the table title" do
    expect(rendered_component).to have_css(".TableTitle", text: "SCIM clients")
  end

  it "renders no actions column by default" do
    expect(rendered_component).to have_css(".TableHead .TableHeader", count: 2)
  end

  context "when actions are explicitly enabled" do
    before do
      PocScim::TableComponent.define_method(:has_actions?) { true }
    end

    it "marks the action cell for the trailing mobile grid column" do
      expect(rendered_component).to have_css(".TableCell.op-data-table--actions-column")
    end
  end

  it "marks cells that are hidden on mobile" do
    expect(rendered_component).to have_css(".TableCell.op-data-table--no-mobile")
  end

  it "marks main column cells" do
    expect(rendered_component).to have_css(".TableCell.op-data-table--main-column")
  end

  it "renders mobile labels through the row component" do
    expect(rendered_component).to have_css(".op-border-box-grid__row-label")
  end

  context "with no rows" do
    let(:scim_clients) { [] }

    it "renders the blank slate text as the empty state" do
      expect(rendered_component).to have_text("Nothing here")
      expect(rendered_component).to have_text("Add one to get started")
    end
  end
end
