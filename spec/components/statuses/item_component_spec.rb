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

RSpec.describe Statuses::ItemComponent, type: :component do
  subject(:rendered_component) do
    with_request_url("/statuses") do
      render_inline(
        described_class.new(status:, max_position: status.position + 1, page_args:)
      )
    end
  end

  let(:status) { create(:status, name: "In progress", default_done_ratio: 40) }
  let(:page_args) { { page: 1, per_page: 20 } }

  it "renders the status name as a link to its edit page" do
    expect(rendered_component).to have_link("In progress", href: "/statuses/#{status.id}/edit")
  end

  it "shows the colour beside the name rather than in a column of its own" do
    status.update!(color: create(:color, name: "Blue", hexcode: "#1F83D6"))

    expect(rendered_component).to have_css(".op-statuses-list--item--name .color--preview")
  end

  describe "flag columns" do
    context "when the status is the default one" do
      let(:status) { create(:status, name: "New", is_default: true) }

      it "checks the default column" do
        expect(rendered_component).to have_css("[aria-label='Default']")
      end
    end

    context "when the status is closed" do
      let(:status) { create(:status, name: "Closed", is_closed: true) }

      it "checks the closed column" do
        expect(rendered_component).to have_css("[aria-label='Closed']")
      end
    end

    context "when the status is read-only", with_ee: %i[readonly_work_packages] do
      let(:status) { create(:status, name: "Rejected", is_readonly: true) }

      it "checks the read-only column" do
        expect(rendered_component).to have_css("[aria-label='Read-only']")
      end
    end

    context "when the status is read-only without an enterprise token", with_ee: false do
      let(:status) { create(:status, name: "Rejected", is_readonly: true) }

      it "leaves the read-only column unchecked, since the flag has no effect" do
        expect(rendered_component).to have_no_css("[aria-label='Read-only']")
      end
    end

    context "when the status carries no flag" do
      it "leaves every flag column unchecked", :aggregate_failures do
        expect(rendered_component).to have_no_css("[aria-label='Default']")
        expect(rendered_component).to have_no_css("[aria-label='Closed']")
        expect(rendered_component).to have_no_css("[aria-label='Read-only']")
      end
    end
  end

  describe "% Complete" do
    context "in status-based progress mode", with_settings: { work_package_done_ratio: "status" } do
      it "shows the default % Complete of the status" do
        expect(rendered_component).to have_test_selector("done-ratio", text: "40%")
      end
    end

    context "in work-based progress mode", with_settings: { work_package_done_ratio: "field" } do
      it "omits % Complete, which has no effect in that mode" do
        expect(rendered_component).to have_no_test_selector("done-ratio")
      end
    end
  end
end
