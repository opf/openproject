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

RSpec.describe "Manage webhooks through UI", :js, :selenium do
  before do
    login_as user
  end

  context "as regular user" do
    let(:user) { create(:user) }

    it "forbids accessing the webhooks management view" do
      visit admin_outgoing_webhooks_path
      expect(page).to have_text "[Error 403]"
    end
  end

  context "as admin" do
    let(:user) { create(:admin) }
    let!(:project) { create(:project) }

    it "allows the management flow" do
      visit admin_outgoing_webhooks_path
      expect(page).to have_css(".generic-table--empty-row")

      # Visit inline create
      find(".wp-inline-create--add-link").click
      SeleniumHubWaiter.wait

      # Fill in elements
      fill_in "webhook_name", with: "My webhook"
      fill_in "webhook_url", with: "http://example.org"

      # Check one event
      find('.form--check-box[value="work_package:created"]').set true

      # Create
      click_on "Create"

      #
      # 1st webhook created
      #

      expect_flash(message: I18n.t(:notice_successful_create))
      expect(page).to have_css(".webhooks--outgoing-webhook-row .name", text: "My webhook")
      webhook = Webhooks::Webhook.last
      expect(webhook.event_names).to eq %w(work_package:created)
      expect(webhook.all_projects).to be_truthy

      expect(page).to have_css(".webhooks--outgoing-webhook-row .enabled .icon-yes")
      expect(page).to have_css(".webhooks--outgoing-webhook-row .selected_projects", text: "All projects")
      expect(page).to have_css(".webhooks--outgoing-webhook-row .events", text: "Work packages")
      expect(page).to have_css(".webhooks--outgoing-webhook-row .description", text: webhook.description)

      SeleniumHubWaiter.wait
      # Edit this webhook
      find(".webhooks--outgoing-webhook-row-#{webhook.id} .icon-edit").click

      SeleniumHubWaiter.wait
      # Check the other event
      find('.form--check-box[value="work_package:created"]').set false
      find('.form--check-box[value="work_package:updated"]').set true

      # Check a subset of projects
      choose "webhook_project_ids_selection"
      find(".webhooks--selected-project-ids[value='#{project.id}']").set true

      click_on "Save"
      expect_flash(message: I18n.t(:notice_successful_update))
      expect(page).to have_css(".webhooks--outgoing-webhook-row .name", text: "My webhook")
      webhook = Webhooks::Webhook.last
      expect(webhook.event_names).to eq %w(work_package:updated)
      expect(webhook.projects.all).to eq [project]
      expect(webhook.all_projects).to be_falsey

      SeleniumHubWaiter.wait
      # Delete webhook

      accept_confirm do
        find(".webhooks--outgoing-webhook-row-#{webhook.id} .icon-delete").click
      end

      expect_flash(message: I18n.t(:notice_successful_delete))
      expect(page).to have_css(".generic-table--empty-row")
    end

    context "with existing webhook" do
      let!(:webhook) { create(:webhook, name: "testing") }
      let!(:log) { create(:webhook_log, response_headers: { test: :foo }, webhook:) }

      it "shows the delivery" do
        visit admin_outgoing_webhooks_path
        SeleniumHubWaiter.wait
        find(".webhooks--outgoing-webhook-row .name a", text: "testing").click

        expect(page).to have_css(".on-off-status.-enabled")
        expect(page).to have_css("td.event_name", text: "foo")
        expect(page).to have_css("td.response_code", text: "200")

        # Open modal
        SeleniumHubWaiter.wait
        find("td.response_body").click_on "Show"

        page.within(".spot-modal") do
          expect(page).to have_css(".webhooks--response-headers strong", text: "test")
          expect(page).to have_css(".webhooks--response-body", text: log.response_body)
        end
      end

      context "with multiple logs" do
        let!(:log2) { create(:webhook_log, response_body: "This is the second log", webhook:) }
        let!(:log3) { create(:webhook_log, response_body: "This is the third log", webhook:) }

        it "shows the response of the log being clicked" do
          visit admin_outgoing_webhook_path(webhook)

          # Open modal
          SeleniumHubWaiter.wait

          all("tbody tr").each do |row_element|
            matching_log = nil
            within(row_element) do
              id = find("td.id").text.to_i
              matching_log = [log, log2, log3].find { |l| l.id == id }
              find("td.response_body").click_on "Show"
            end

            page.within(".spot-modal") do
              expect(page).to have_css(".webhooks--response-body", text: matching_log.response_body)
              click_button("Close")
            end
          end
        end
      end
    end
  end
end
