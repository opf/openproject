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

RSpec.describe "Omniauth authentication" do
  # Load ViewAccountLoginAuthProvider to have this spec passing
  OpenProject::Hooks::ViewAccountLoginAuthProvider

  let(:mail) { "omnibob@example.com" }
  let(:login) { "omnibob" }
  let(:firstname) { "omni" }
  let(:lastname) { "bob" }
  let(:user) do
    create(:user,
           force_password_change: false,
           login:,
           mail:,
           firstname:,
           lastname:)
  end
  let(:user_menu) { Components::UserMenu.new }

  before do
    @omniauth_test_mode = OmniAuth.config.test_mode
    @capybara_ignore_elements = Capybara.ignore_hidden_elements
    @omniauth_logger = OmniAuth.config.logger
    OmniAuth.config.logger = Rails.logger
    Capybara.ignore_hidden_elements = false
  end

  after do
    OmniAuth.config.test_mode = @omniauth_test_mode
    Capybara.ignore_hidden_elements = @capybara_ignore_elements
    OmniAuth.config.logger = @omniauth_logger
  end

  describe "existing user sign in" do
    it "redirects to back url" do
      visit account_lost_password_path
      click_link("Omniauth Developer", match: :first, visible: :all)

      SeleniumHubWaiter.wait
      fill_in("first_name", with: user.firstname)
      fill_in("last_name", with: user.lastname)
      fill_in("email", with: user.mail)
      click_link_or_button "Sign In"

      expect(current_url).to eql home_url
    end

    it "signs in user" do
      visit "/auth/developer"

      SeleniumHubWaiter.wait
      fill_in("first_name", with: user.firstname)
      fill_in("last_name", with: user.lastname)
      fill_in("email", with: user.mail)
      click_link_or_button "Sign In"

      user_menu.expect_user_shown "omni bob"
      expect(page).to have_link("Sign out")
    end

    context "with direct login",
            with_settings: { omniauth_direct_login_provider: "developer" } do
      it "goes directly to the developer sign in and then redirect to the back url" do
        visit my_account_path
        # requires login, redirects to developer login which is why we see the login form now

        SeleniumHubWaiter.wait
        fill_in("first_name", with: user.firstname)
        fill_in("last_name", with: user.lastname)
        fill_in("email", with: user.mail)
        click_link_or_button "Sign In"

        expect(current_path).to eql my_account_path

        # Expect the dropdown menu to be the logged in one
        expect(page).to have_test_selector "op-app-header--user-menu-button"
      end
    end
  end

  describe "sign out a user with direct login and login required",
           with_settings: { omniauth_direct_login_provider: "developer", login_required: true } do
    it "shows a notice that the user has been logged out" do
      visit signout_path

      expect(page).to have_content(I18n.t(:notice_logged_out))
      expect(page).to have_content "You can sign in again by clicking"
    end

    it "sign-in after previous sign-out shows my page" do
      visit signout_path

      expect(page).to have_content(I18n.t(:notice_logged_out))

      click_on "here"

      SeleniumHubWaiter.wait
      fill_in("first_name", with: user.firstname)
      fill_in("last_name", with: user.lastname)
      fill_in("email", with: user.mail)
      click_link_or_button "Sign In"

      expect(current_url).to eq home_url
    end
  end

  shared_examples "omniauth user registration" do
    it "registers new user" do
      visit "/"
      click_link("Omniauth Developer", match: :first)

      SeleniumHubWaiter.wait
      # login form developer strategy
      fill_in("first_name", with: firstname)
      # intentionally do not supply last_name
      fill_in("email", with: mail)
      click_link_or_button "Sign In"

      expect(page).to have_content "Last name can't be blank"
      # on register form, we are prompted for a last name
      within("#content") do
        SeleniumHubWaiter.wait
        fill_in("user_lastname", with: lastname)
        click_link_or_button "Create"
      end

      expect(page).to have_content(I18n.t(:notice_account_registered_and_logged_in))
      expect(page).to have_link("Sign out")
    end
  end

  describe "on-the-fly registration",
           with_settings: {
             self_registration?: true,
             self_registration: Setting::SelfRegistration.automatic
           } do
    it_behaves_like "omniauth user registration"

    it "redirects to homescreen" do
      visit account_lost_password_path
      click_link("Omniauth Developer", match: :first)

      SeleniumHubWaiter.wait
      # login form developer strategy
      fill_in("first_name", with: firstname)
      # intentionally do not supply last_name
      fill_in("email", with: mail)
      click_link_or_button "Sign In"

      # on register form, we are prompted for a last name
      within("#content") do
        SeleniumHubWaiter.wait
        fill_in("user_lastname", with: lastname)
        click_link_or_button "Create"
      end

      expect(page).to have_current_path home_path(first_time_user: true)
    end

    context "with password login disabled",
            with_config: { disable_password_login: "true" } do
      it_behaves_like "omniauth user registration"
    end
  end

  describe "email registration",
           with_settings: {
             self_registration: Setting::SelfRegistration.by_email
           } do
    shared_examples "registration with registration by email" do
      it "still automatically activates the omniauth account" do
        visit login_path

        SeleniumHubWaiter.wait
        # login form developer strategy
        fill_in "email", with: user.mail

        click_link_or_button "Sign In"

        expect(page).to have_current_path home_path
      end
    end

    it_behaves_like "registration with registration by email" do
      let(:login_path) { "/auth/developer" }
    end

    context "with direct login enabled and login required",
            with_settings: { omniauth_direct_login_provider: "developer", login_required: true } do
      it_behaves_like "registration with registration by email" do
        let(:login_path) { "/auth/developer" }
      end

      context "when authorizing an external OAuth app" do
        let(:oauth_client) { create(:oauth_application, redirect_uri: "https://rp.example.com/callback") }

        it "logs in and registers successfully" do
          visit oauth_authorization_path(
            client_id: oauth_client.uid,
            redirect_uri: oauth_client.redirect_uri,
            response_type: "code",
            prompt: "login"
          )

          SeleniumHubWaiter.wait
          fill_in "email", with: user.mail # login form developer strategy

          click_link_or_button "Sign In"

          expect(page).to have_current_path(oauth_authorization_path, ignore_query: true)
        end
      end
    end
  end

  describe "error handling" do
    shared_examples "omniauth signin error" do
      it "fails with generic error message" do
        # set omniauth to test mode will redirect all calls to omniauth
        # directly to the callback and by setting the mock_auth provider
        # to a symbol will force omniauth to fail /auth/failure
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth[:developer] = :invalid_credentials
        # seems like this default behaviour is removed when running the full
        # test suite, so let's set it back when running this test
        OmniAuth.config.on_failure = Proc.new do |env|
          OmniAuth::FailureEndpoint.new(env).redirect_to_failure
        end
        visit login_path
        expect(page).to have_content(I18n.t(:error_external_authentication_failed_message, message: "Unknown error"))

        if defined? instructions
          expect(page).to have_content instructions
        end
      end
    end

    it_behaves_like "omniauth signin error" do
      let(:login_path) { "/auth/developer" }
    end

    context "with direct login and login required",
            with_settings: { omniauth_direct_login_provider: "developer", login_required: true } do
      it_behaves_like "omniauth signin error" do
        let(:login_path) { signin_path }
        let(:instructions) { "You can try to sign in again by clicking" }
      end
    end
  end
end
