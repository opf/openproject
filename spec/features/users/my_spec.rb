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

RSpec.describe "my", :js, :with_cuprite do
  let(:user_password) { "bob" * 4 }
  let!(:string_cf) { create(:user_custom_field, :string, name: "Hobbies", is_required: false) }
  let(:user) do
    create(:user,
           mail: "old@mail.com",
           login: "bob",
           password: user_password,
           password_confirmation: user_password)
  end

  ##
  # Expectations for a successful account change
  def expect_changed!
    expect(page).to have_content I18n.t(:notice_account_updated)
    expect(page).to have_content I18n.t(:notice_account_other_session_expired)

    # expect session to be removed
    expect(Sessions::UserSession.for_user(user).where(session_id: "other").count).to eq 0

    user.reload
    expect(user.mail).to eq "foo@mail.com"
    expect(user.name).to eq "Foo Bar"
  end

  before do
    login_as user

    # Create dangling session
    session = Sessions::SqlBypass.new data: { user_id: user.id }, session_id: "other"
    session.save

    expect(Sessions::UserSession.for_user(user).where(session_id: "other").count).to eq 1
  end

  shared_examples "common tests for normal and LDAP user" do
    describe "settings" do
      context "with a default time zone", with_settings: { user_default_timezone: "Asia/Tokyo" } do
        it "can override a time zone" do
          expect(user.pref.time_zone).to eq "Asia/Tokyo"
          visit my_settings_path

          expect(page).to have_select "pref_time_zone", selected: "(UTC+09:00) Tokyo"
          select "(UTC+01:00) Paris", from: "pref_time_zone"
          click_on "Save"

          expect(page).to have_select "pref_time_zone", selected: "(UTC+01:00) Paris"
          expect(user.pref.time_zone).to eq "Europe/Paris"
        end
      end
    end
  end

  context "user" do
    describe "#account" do
      let(:dialog) { Components::PasswordConfirmationDialog.new }

      before do
        visit my_account_path

        fill_in "user[mail]", with: "foo@mail.com"
        fill_in "user[firstname]", with: "Foo"
        fill_in "user[lastname]", with: "Bar"
        click_on "Save"
      end

      context "when confirmation disabled",
              with_config: { internal_password_confirmation: false } do
        it "does not request confirmation" do
          expect_changed!
        end
      end

      context "when confirmation required",
              with_config: { internal_password_confirmation: true } do
        it "requires the password for a regular user" do
          dialog.confirm_flow_with(user_password)
          expect_changed!
        end

        it "declines the change when invalid password is given" do
          dialog.confirm_flow_with(user_password + "INVALID", should_fail: true)

          user.reload
          expect(user.mail).to eq("old@mail.com")
        end

        context "as admin" do
          shared_let(:admin) { create(:admin) }
          let(:user) { admin }

          it "requires the password" do
            dialog.confirm_flow_with("adminADMIN!")
            expect_changed!
          end
        end
      end
    end

    include_examples "common tests for normal and LDAP user"

    describe "API tokens" do
      context "when API access is disabled via global settings", with_settings: { rest_api_enabled: false } do
        it "shows notice about disabled token" do
          visit my_access_token_path

          within "#api-token-section" do
            expect(page).to have_content("API tokens are not enabled by the administrator.")
            expect(page).not_to have_test_selector("api-token-add", text: "API token")
          end
        end
      end

      context "when API access is enabled via global settings", with_settings: { rest_api_enabled: true } do
        it "API tokens can be generated and revoked" do
          visit my_access_token_path

          expect(page).to have_no_content("API tokens are not enabled by the administrator.")

          within "#api-token-section" do
            expect(page).to have_test_selector("api-token-add", text: "API token")
            find_test_selector("api-token-add").click
          end

          expect(page).to have_test_selector("new-access-token-dialog")

          # create API token
          fill_in "token_api[token_name]", with: "Testing Token"
          find_test_selector("create-api-token-button").click

          within("dialog#access-token-created-dialog") do
            expect(page).to have_content "The API token has been generated"
            click_on "Close"
          end
          expect(page).to have_content("Testing Token")

          User.current.reload
          visit my_access_token_path

          # multiple API tokens can be created
          within "#api-token-section" do
            expect(page).to have_test_selector("api-token-add", text: "API token")
          end

          # revoke API token
          within "#api-token-section" do
            accept_confirm do
              find_test_selector("api-token-revoke").click
            end
          end

          expect(page).to have_content "The API token has been deleted."

          User.current.reload
          visit my_access_token_path

          # API token can be created again
          within "#api-token-section" do
            expect(page).to have_test_selector("api-token-add", text: "API token")
          end
        end
      end
    end

    describe "RSS tokens" do
      context "when RSS access is disabled via global settings", with_settings: { feeds_enabled: false } do
        it "shows notice about disabled token" do
          visit my_access_token_path

          within "#rss-token-section" do
            expect(page).to have_content("RSS tokens are not enabled by the administrator.")
            expect(page).not_to have_test_selector("rss-token-add", text: "RSS token")
          end
        end
      end

      context "when RSS access is enabled via global settings", with_settings: { feeds_enabled: true } do
        it "in Access Tokens they can generate and revoke their RSS key" do
          visit my_access_token_path

          expect(page).to have_no_content("RSS tokens are not enabled by the administrator.")

          within "#rss-token-section" do
            expect(page).to have_test_selector("rss-token-add", text: "RSS token")
            find_test_selector("rss-token-add").click
          end

          expect(page).to have_content "A new RSS token has been generated. Your access token is"

          User.current.reload
          visit my_access_token_path

          # only one RSS token can be created
          within "#rss-token-section" do
            expect(page).not_to have_test_selector("rss-token-add", text: "RSS token")
          end

          # revoke RSS token
          within "#rss-token-section" do
            accept_confirm do
              find_test_selector("rss-token-revoke").click
            end
          end

          expect(page).to have_content "The RSS token has been deleted."

          User.current.reload
          visit my_access_token_path

          # RSS token can be created again
          within "#rss-token-section" do
            expect(page).to have_test_selector("rss-token-add", text: "RSS token")
          end
        end
      end
    end

    describe "iCalendar tokens" do
      context "when iCalendar access is disabled via global settings", with_settings: { ical_enabled: false } do
        it "shows notice about disabled token" do
          visit my_access_token_path

          within "#icalendar-token-section" do
            expect(page).to have_content("iCalendar subscriptions are not enabled by the administrator.")
          end
        end
      end

      context "when iCalendar access is enable via global settings", with_settings: { ical_enabled: true } do
        context "when no iCalendar token exists" do
          it "shows notice about how to use iCalendar tokens" do
            visit my_access_token_path

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
            visit my_access_token_path

            expect(page).to have_no_content("To add an iCalendar token") # ...

            within "#icalendar-token-section" do
              [
                ical_token_for_query,
                ical_token_for_another_query,
                second_ical_token_for_query
              ].each do |ical_token|
                token_name = ical_token.ical_token_query_assignment.name
                query = ical_token.ical_token_query_assignment.query

                expect(page).to have_test_selector("ical-token-row-#{ical_token.id}-name", text: token_name)
                expect(page).to have_test_selector("ical-token-row-#{ical_token.id}-query-name", text: query.name)
                expect(page).to have_test_selector("ical-token-row-#{ical_token.id}-project-name",
                                                   text: query.project.name)
              end
            end
          end

          it "single iCalendar tokens can be deleted" do
            visit my_access_token_path

            within "#icalendar-token-section" do
              accept_confirm do
                find_test_selector("ical-token-row-#{ical_token_for_query.id}-revoke").click
              end
            end

            expect(page).to have_content "The iCalendar URL with this token is now invalid."

            User.current.reload
            visit my_access_token_path

            within "#icalendar-token-section" do
              expect(page).not_to have_test_selector('ical-token-row-#{ical_token_for_query.id}-revoke')
            end
          end
        end
      end
    end

    describe "OAuth tokens" do
      context "when no OAuth access is configured" do
        it "shows notice about no existing tokens" do
          visit my_access_token_path

          within "#oauth-token-section" do
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
            visit my_access_token_path

            [app, second_app].each do |app|
              within "#oauth-token-section" do
                expect(page).to have_test_selector("oauth-token-row-#{app.id}-name", text: app.name)
                expect(page).to have_test_selector("oauth-token-row-#{app.id}-name", text: "(one active token)")
              end
            end
          end

          it "can revoke tokens" do
            visit my_access_token_path

            [app, second_app].each do |app|
              within "#oauth-token-section" do
                accept_confirm do
                  find_test_selector("oauth-token-row-#{app.id}-revoke").click
                end
              end
            end

            User.current.reload
            visit my_access_token_path

            [app, second_app].each do |app|
              within "#oauth-token-section" do
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
            visit my_access_token_path

            [app, second_app].each do |app|
              within "#oauth-token-section" do
                expect(page).to have_test_selector("oauth-token-row-#{app.id}-name", text: app.name)
                expect(page).to have_test_selector("oauth-token-row-#{app.id}-name", text: "(2 active token)")
              end
            end
          end

          it "can revoke mutliple tokens per app" do
            visit my_access_token_path

            within "#oauth-token-section" do
              accept_confirm do
                find_test_selector("oauth-token-row-#{app.id}-revoke").click
              end
            end

            User.current.reload
            visit my_access_token_path

            within "#oauth-token-section" do
              expect(page).not_to have_test_selector("oauth-token-row-#{app.id}-revoke")
            end
          end
        end
      end
    end
  end

  # Without password confirmation the test doesn't try to connect to the LDAP:
  context "LDAP user", with_config: { internal_password_confirmation: false } do
    let(:ldap_auth_source) { create(:ldap_auth_source) }
    let(:user) do
      create(:user,
             mail: "old@mail.com",
             login: "bob",
             ldap_auth_source:)
    end

    describe "#account" do
      before do
        visit my_account_path
      end

      it "does not allow change of name and email but other fields can be changed" do
        email_field = find_field("user[mail]", disabled: true)
        firstname_field = find_field("user[firstname]", disabled: true)
        lastname_field = find_field("user[lastname]", disabled: true)

        expect(email_field).to be_disabled
        expect(firstname_field).to be_disabled
        expect(lastname_field).to be_disabled

        expect(page).to have_text(I18n.t("user.text_change_disabled_for_ldap_login"), count: 3)

        fill_in "Hobbies", with: "Ruby, DCS"
        uncheck "pref[hide_mail]"
        click_on "Save"

        expect(page).to have_content I18n.t(:notice_account_updated)

        user.reload
        expect(user.custom_values.find_by(custom_field_id: string_cf).value).to eql "Ruby, DCS"
        expect(user.pref.hide_mail).to be false
      end
    end

    include_examples "common tests for normal and LDAP user"
  end
end
