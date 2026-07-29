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

RSpec.describe RowComponent, type: :component do
  describe "generic rows" do
    let(:status) { create(:status, name: "In progress") }
    let(:table) { Statuses::TableComponent.new(rows: [status]) }

    it "renders only the requested column's contents" do
      render_inline(Statuses::RowComponent.new(row: status, table:, render_only: :name))

      expect(page).to have_link("In progress")
      expect(page).to have_no_css("tr")
      expect(page).to have_no_css("td")
    end

    it "renders only the action links" do
      render_inline(
        Statuses::RowComponent.new(row: status, table:, render_only: described_class::ACTIONS_CELL)
      )

      path = Rails.application.routes.url_helpers.status_path(status)
      expect(page).to have_css("a[href='#{path}']")
      expect(page).to have_no_css("td.buttons")
    end
  end

  describe "border box rows" do
    let(:scim_client) { create(:scim_client) }
    let(:table) { Admin::ScimClients::TableComponent.new(rows: [scim_client]) }

    before do
      allow(table)
        .to receive(:column_title)
        .with(:created_at)
        .and_return(ScimClient.human_attribute_name(:created_at))
    end

    it "renders the mobile label alongside the value" do
      render_inline(
        Admin::ScimClients::RowComponent.new(row: scim_client, table:, render_only: :created_at)
      )

      expect(page).to have_css(".op-border-box-grid__row-label")
      expect(page).to have_no_css(".op-border-box-grid__row-item")
    end

    it "renders the value alone for a column without a mobile label" do
      render_inline(
        Admin::ScimClients::RowComponent.new(row: scim_client, table:, render_only: :name)
      )

      expect(page).to have_link(scim_client.name)
      expect(page).to have_no_css(".op-border-box-grid__row-label")
    end
  end
end
