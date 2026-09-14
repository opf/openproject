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

require "spec_helper"

RSpec.describe "my access tokens", :js do
  let(:user_password) { "bob" * 4 }
  let!(:string_cf) { create(:user_custom_field, :string, name: "Hobbies", is_required: false) }
  let(:user) do
    create(:user,
           mail: "old@mail.com",
           login: "bob",
           password: user_password,
           password_confirmation: user_password)
  end

  before do
    login_as user
  end

  describe "API tokens" do
    context "when API tokens are disabled via global setting", with_settings: { api_tokens_enabled: false } do
      it "shows notice about disabled token" do
        visit my_access_tokens_path

        within "#api-token-component" do
          expect(page).to have_content("API tokens are not enabled by the administrator.")
          expect(page).not_to have_test_selector("api-token-add", text: "API token")
        end
      end
    end

    context "when API tokens are enabled via global setting", with_settings: { api_tokens_enabled: true } do
      it "API tokens can be generated and revoked" do
        visit my_access_tokens_path

        expect(page).to have_no_content("API tokens are not enabled by the administrator.")

        within "#api-token-component" do
          expect(page).to have_test_selector("api-token-add", text: "API token")
          find_test_selector("api-token-add").click
        end

        expect(page).to have_test_selector("new-access-token-dialog")

        # create API token
        fill_in "token_api[token_name]", with: "Testing Token"
        wait_for_turbo_stream { find_test_selector("create-api-token-button").click }

        within("dialog#api-created-dialog") do
          expect(page).to have_content "The API token has been generated"
          expect(page).to have_field("openproject_api_access_token", with: %r{[a-f0-9]{64}}, readonly: true)
          click_on "Close"
        end
        expect(page).to have_content("Testing Token")

        User.current.reload
        visit my_access_tokens_path

        # multiple API tokens can be created
        within "#api-token-component" do
          expect(page).to have_test_selector("api-token-add", text: "API token")
        end

        # revoke API token
        within "#api-token-component" do
          accept_confirm do
            find_test_selector("api-token-revoke").click
          end
        end

        expect(page).to have_content "The API token has been deleted."

        User.current.reload
        visit my_access_tokens_path

        within "#api-token-component" do
          # make sure the token is not there anymore
          expect(page).to have_no_content("Testing Token")

          # API token can be created again
          expect(page).to have_test_selector("api-token-add", text: "API token")
        end
      end
    end
  end

  describe "RSS tokens" do
    context "when RSS access is disabled via global settings", with_settings: { feeds_enabled: false } do
      it "shows notice about disabled token" do
        visit my_access_tokens_path

        within "#rss-token-component" do
          expect(page).to have_content("RSS tokens are not enabled by the administrator.")
          expect(page).not_to have_test_selector("rss-token-add", text: "RSS token")
        end
      end
    end

    context "when RSS access is enabled via global settings", with_settings: { feeds_enabled: true } do
      it "in Access tokens they can generate and revoke their RSS key" do
        visit my_access_tokens_path

        expect(page).to have_no_content("RSS tokens are not enabled by the administrator.")

        within "#rss-token-component" do
          expect(page).to have_test_selector("rss-token-add", text: "RSS token")
          find_test_selector("rss-token-add").click
        end

        expect(page).to have_content "The RSS token has been generated"

        User.current.reload
        visit my_access_tokens_path

        # only one RSS token can be created
        within "#rss-token-component" do
          expect(page).not_to have_test_selector("rss-token-add", text: "RSS token")
        end

        # revoke RSS token
        within "#rss-token-component" do
          accept_confirm do
            find_test_selector("api-token-revoke").click
          end
        end

        expect(page).to have_content "The RSS token has been deleted."

        User.current.reload
        visit my_access_tokens_path

        # RSS token can be created again
        within "#rss-token-component" do
          expect(page).to have_test_selector("rss-token-add", text: "RSS token")
        end
      end
    end
  end

  describe "iCalendar tokens" do
    context "when iCalendar access is disabled via global settings", with_settings: { ical_enabled: false } do
      it "shows notice about disabled token" do
        visit my_access_tokens_path

        within "#icalendar-token-section" do
          expect(page).to have_content("iCalendar subscriptions are not enabled by the administrator.")
        end
      end
    end

    context "when iCalendar access is enable via global settings", with_settings: { ical_enabled: true } do
      context "when no iCalendar token exists" do
        it "shows notice about how to use iCalendar tokens" do
          visit my_access_tokens_path

          within "#icalendar-token-section" do
            expect(page).to have_content("To add an iCalendar token") # ...
          end
        end
      end

      context "when multiple iCalendar tokens exist" do
        let!(:project) { create(:project) }
        let!(:query) { create(:query, project:) }
        let!(:another_query) { create(:query, project:) }
        let!(:ical_token_for_query) { create(:ical_token, user:, query:, name: "First Token Name") }
        let!(:ical_token_for_another_query) { create(:ical_token, user:, query: another_query, name: "Second Token Name") }
        let!(:second_ical_token_for_query) { create(:ical_token, user:, query:, name: "Third Token Name") }

        it "shows iCalendar tokens with their calender and project info" do
          visit my_access_tokens_path

          expect(page).to have_no_content("To add an iCalendar token") # ...

          within "#icalendar-token-section" do
            [
              ical_token_for_query,
              ical_token_for_another_query,
              second_ical_token_for_query
            ].each do |ical_token|
              token_name = ical_token.ical_token_query_assignment.name
              query = ical_token.ical_token_query_assignment.query

              expect(page).to have_test_selector("ical-token-#{ical_token.id}-name", text: token_name)
              expect(page).to have_test_selector("ical-token-#{ical_token.id}-query-name", text: query.name)
              expect(page).to have_test_selector("ical-token-#{ical_token.id}-project-name",
                                                 text: query.project.name)
            end
          end
        end

        it "single iCalendar tokens can be deleted" do
          visit my_access_tokens_path

          within "#icalendar-token-section" do
            accept_confirm do
              find_test_selector("ical-token-#{ical_token_for_query.id}-revoke").click
            end
          end

          expect(page).to have_content "The iCalendar URL with this token is now invalid."

          User.current.reload
          visit my_access_tokens_path

          within "#icalendar-token-section" do
            expect(page).not_to have_test_selector("ical-token-#{ical_token_for_query.id}-revoke")
          end
        end
      end
    end
  end

  describe "iCal Meeting tokens" do
    context "when iCal access is disabled via global settings", with_settings: { ical_enabled: false } do
      it "shows notice about disabled token" do
        visit my_access_tokens_path

        within "#ical_meeting-token-component" do
          expect(page).to have_content("iCalendar meeting subscriptions are not enabled by the administrator. Please contact your administrator to use this feature.")
          expect(page).not_to have_test_selector("ical_meeting-token-add", text: "Subscribe to calendar")
        end
      end
    end

    context "when iCal access is enabled via global settings", with_settings: { ical_enabled: true } do
      it "iCal tokens can be generated and revoked" do
        visit my_access_tokens_path

        expect(page).to have_no_content("iCalendar meeting subscriptions are not enabled by the administrator. Please contact your administrator to use this feature.")

        within "#ical_meeting-token-component" do
          expect(page).to have_test_selector("ical_meeting-token-add", text: "Subscribe to calendar")
          find_test_selector("ical_meeting-token-add").click
        end

        expect(page).to have_test_selector("new-access-token-dialog")

        # create iCal meeting token
        fill_in "token_ical_meeting[token_name]", with: "Testing Token"
        find_test_selector("create-api-token-button").click

        within("dialog#ical_meeting-created-dialog") do
          expect(page).to have_content "An iCal meeting subscription token has been generated"
          expect(page).to have_field("openproject_api_access_token",
                                     with: %r{http(s?)://[^/]+/meetings/ical/[a-f0-9]{64}.ics},
                                     readonly: true)
          click_on "Close"
        end
        expect(page).to have_content("Testing Token")

        User.current.reload
        visit my_access_tokens_path

        # multiple iCal meeting tokens can be created
        within "#ical_meeting-token-component" do
          expect(page).to have_test_selector("ical_meeting-token-add", text: "Subscribe to calendar")
        end

        # revoke iCal meeting token
        within "#ical_meeting-token-component" do
          accept_confirm do
            find_test_selector("api-token-revoke").click
          end
        end

        expect(page).to have_content I18n.t("my.access_token.revocation.token/ical_meeting.notice_success")

        User.current.reload
        visit my_access_tokens_path

        within "#ical_meeting-token-component" do
          # make sure the token is not there anymore
          expect(page).to have_no_content("Testing Token")

          # API token can be created again
          expect(page).to have_test_selector("ical_meeting-token-add", text: "Subscribe to calendar")
        end
      end
    end
  end

  describe "OAuth tokens" do
    context "when no OAuth access is configured" do
      it "shows notice about no existing tokens" do
        visit my_access_tokens_path

        within "#oauth-application-token-section" do
          expect(page).to have_content("There is no third-party application access configured and active for you")
        end
      end
    end

    context "when OAuth access is configured" do
      let!(:app) do
        create(:oauth_application,
               name: "Some App",
               confidential: false)
      end
      let!(:token_for_app) do
        create(:oauth_access_token,
               application: app,
               resource_owner: user)
      end
      let!(:second_app) do
        create(:oauth_application,
               name: "Some Second App",
               uid: "56789",
               confidential: false)
      end
      let!(:token_for_second_app) do
        create(:oauth_access_token,
               application: second_app,
               resource_owner: user)
      end

      context "when single OAuth token per app is configured" do
        it "shows token for granted applications" do
          visit my_access_tokens_path

          [app, second_app].each do |app|
            within "#oauth-application-token-section" do
              expect(page).to have_test_selector("oauth-application-#{app.id}-name", text: app.name)
              expect(page).to have_test_selector("oauth-application-#{app.id}-active-tokens", text: "1")
            end
          end
        end

        it "can revoke tokens" do
          visit my_access_tokens_path

          [app, second_app].each do |app|
            within "#oauth-application-token-section" do
              accept_confirm do
                find_test_selector("oauth-token-row-#{app.id}-revoke").click
              end
            end
            expect_and_dismiss_flash message: "Revocation of application #{app.name} successful."
          end

          User.current.reload
          visit my_access_tokens_path

          [app, second_app].each do |app|
            within "#oauth-application-token-section" do
              expect(page).not_to have_test_selector("oauth-token-row-#{app.id}-revoke")
            end
          end
        end
      end

      context "when multiple OAuth tokens per app are configured" do
        let!(:second_token_for_app) do
          create(:oauth_access_token,
                 application: app,
                 resource_owner: user)
        end
        let!(:second_token_for_second_app) do
          create(:oauth_access_token,
                 application: second_app,
                 resource_owner: user)
        end

        it "shows token for granted applications" do
          visit my_access_tokens_path

          [app, second_app].each do |app|
            within "#oauth-application-token-section" do
              expect(page).to have_test_selector("oauth-application-#{app.id}-name", text: app.name)
              expect(page).to have_test_selector("oauth-application-#{app.id}-active-tokens", text: "2")
            end
          end
        end

        it "can revoke mutliple tokens per app" do
          visit my_access_tokens_path

          within "#oauth-application-token-section" do
            accept_confirm do
              find_test_selector("oauth-token-row-#{app.id}-revoke").click
            end
          end

          User.current.reload
          visit my_access_tokens_path

          within "#oauth-application-token-section" do
            expect(page).not_to have_test_selector("oauth-token-row-#{app.id}-revoke")
          end
        end
      end
    end
  end
end
