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

RSpec.describe Admin::ScimClients::TableComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  subject(:rendered_component) do
    render_component(rows: scim_clients)
  end

  shared_examples_for "rendering the column headings" do
    it "renders a heading per column", :aggregate_failures do
      ["Name", "Users", "Authentication method", "Created on"].each do |caption|
        expect(rendered_component).to have_css "th", text: caption
      end
    end

    it "renders the table title" do
      expect(rendered_component).to have_css ".TableTitle", text: "SCIM clients"
    end
  end

  context "with no SCIM clients" do
    let(:scim_clients) { create_list(:scim_client, 0) }

    it "renders no data rows" do
      expect(rendered_component).to have_no_css "tbody tr"
    end

    it "renders the table title" do
      expect(rendered_component).to have_css ".TableTitle", text: "SCIM clients"
    end

    it "renders the empty state" do
      expect(rendered_component).to have_text "No SCIM clients configured yet"
    end
  end

  context "with SCIM clients" do
    let(:scim_clients) { create_list(:scim_client, 2) }

    it_behaves_like "rendering the column headings"

    it "renders a data table" do
      expect(rendered_component).to have_css ".TableContainer .Table"
    end

    it "renders a row per client with a cell per column", :aggregate_failures do
      expect(rendered_component).to have_css "tbody tr", count: 2
      expect(rendered_component).to have_css "tbody tr:first-of-type td, tbody tr:first-of-type th",
                                             count: 4
    end
  end
end
