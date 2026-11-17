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

require "spec_helper"

RSpec.describe "SquashTM server administration", :js do
  current_user { create(:admin, preferences: { warn_on_leaving_unsaved: false }) }

  let(:connection_check) { instance_double(SquashTMIntegration::ConnectionCheck, call: nil) }

  before do
    allow(SquashTMIntegration::ConnectionCheck).to receive(:new).and_return(connection_check)
  end

  it "lists SquashTM under the integrations in the administration" do
    visit admin_index_path

    click_link "Integrations", match: :first
    click_link "SquashTM"

    expect(page).to have_current_path("/squashtm_integration/admin/server")
    expect(page).to have_no_test_selector("squashtm--test-server-connection")
  end

  it "connects OpenProject to a SquashTM server" do
    visit squashtm_integration_admin_server_path

    fill_in "SquashTM URL", with: "https://squashtm.example.com/squash/"
    fill_in "API token", with: "secret-token"
    click_button "Save"

    expect_flash(message: I18n.t(:notice_successful_update))
    expect(page).to have_test_selector("squashtm--linked-server",
                                       text: "OpenProject is linked to the SquashTM server at " \
                                             "https://squashtm.example.com/squash")
    expect(page).to have_no_field("SquashTM URL")
    expect(SquashTMIntegration::Server.sole.api_token).to eq("secret-token")
  end

  it "saves the server and warns when the connection check fails" do
    allow(connection_check).to receive(:call) { |errors| errors.add(:base, :api_token_rejected) }
    visit squashtm_integration_admin_server_path

    fill_in "SquashTM URL", with: "https://squashtm.example.com/squash"
    fill_in "API token", with: "wrong-token"
    click_button "Save"

    expect_flash(type: :warning, message: /The settings were saved, but .*The SquashTM server rejected the API token\./)
    expect(SquashTMIntegration::Server.sole.api_token).to eq("wrong-token")
  end

  context "with a configured server" do
    before do
      create(:squashtm_server)
      visit squashtm_integration_admin_server_path
    end

    it "shows the linked server and hides the form" do
      within_test_selector("squashtm--linked-server") do
        expect(page).to have_text("OpenProject is linked to the SquashTM server at https://squashtm.example.com/squash")
        expect(page).to have_link("https://squashtm.example.com/squash", href: "https://squashtm.example.com/squash")
        expect(find_link("https://squashtm.example.com/squash")[:target]).to eq("_blank")
      end
      expect(page).to have_no_field("SquashTM URL")
      expect(page).to have_no_field("API token")
      expect(page).to have_test_selector("squashtm--test-server-connection")
      expect(page).to have_test_selector("squashtm--delete-server", text: "Unlink")
      within_test_selector("squashtm--delete-server") { expect(page).to have_css("svg.octicon-unlink") }
    end

    it "tests the connection" do
      find_test_selector("squashtm--test-server-connection").click

      expect_flash(message: "The connection to SquashTM was successful.")
    end

    it "reports why the connection test failed" do
      allow(connection_check).to receive(:call) { |errors| errors.add(:base, :base_url_cannot_be_connected_to, url: "https://squashtm.example.com/squash") }

      find_test_selector("squashtm--test-server-connection").click

      expect_flash(type: :error, message: /The connection to SquashTM failed: .*could not be reached/)
    end

    it "deletes the server after confirmation" do
      find_test_selector("squashtm--delete-server").click
      within_test_selector("squashtm--delete-server-dialog") do
        expect(page).to have_text("Delete the SquashTM server configuration?")
        click_button "Delete"
      end

      expect_flash(message: I18n.t(:notice_successful_delete))
      expect(SquashTMIntegration::Server).not_to exist
    end
  end
end
