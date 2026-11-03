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

require_relative "../../spec_helper"
require_relative "../shared_two_factor_examples"

RSpec.describe "Login with 2FA remember cookie",
               :js,
               with_settings: {
                 plugin_openproject_two_factor_authentication: {
                   active_strategies: [:developer],
                   allow_remember_for_days: 30
                 }
               } do
  include SharedTwoFactorExamples

  let(:user_password) do
    "user!user!"
  end
  let(:user) do
    create(:user, password: user_password, password_confirmation: user_password)
  end
  let!(:device) { create(:two_factor_authentication_device_sms, user:, active: true, default: true) }

  def login_with_cookie
    page.driver.clear_cookies

    sms_token = nil
    allow_any_instance_of(OpenProject::TwoFactorAuthentication::TokenStrategy::Developer)
        .to receive(:create_mobile_otp).and_wrap_original do |m|
      sms_token = m.call
    end

    first_login_step

    expect(page).to have_css("input#remember_me")
    SeleniumHubWaiter.wait
    check "remember_me"

    two_factor_step sms_token
    expect_logged_in
  end

  def expect_no_autologin
    first_login_step

    expect(page).to have_css("input#otp")
    expect_not_logged_in
  end

  context "when not enabled",
          with_settings: {
            plugin_openproject_two_factor_authentication: {
              active_strategies: [:developer],
              allow_remember_for_days: 0
            }
          } do
    it "does not show the save form" do
      first_login_step
      expect(page).to have_no_css("input#remember_me")
    end
  end

  context "when user has no remember cookie" do
    it "can remove the autologin cookie after login" do
      login_with_cookie
      visit my_security_path

      find_test_selector("two-factor-authentication--remove-remember-cookie-link").click
      expect_flash(message: I18n.t("two_factor_authentication.remember.cookie_removed"))
      expect(page).to have_no_test_selector("two-factor-authentication--remove-remember-cookie-link")

      # Log out and in again
      visit "/logout"
      expect_no_autologin
    end

    it "allows to save a cookie on the login step for subsequent steps" do
      login_with_cookie

      # Log out and in again
      visit "/logout"
      first_login_step

      # Expect no OTP required
      expect_logged_in

      # Expire token
      token = TwoFactorAuthentication::RememberedAuthToken.find_by!(user:)
      expect(token).not_to be_expired
      token.update_columns(expires_on: 1.day.ago, created_at: 31.days.ago)

      # Log out and in again
      visit "/logout"
      expect_no_autologin

      # Login to save cookie again
      login_with_cookie

      # Disable functionality
      allow(OpenProject::TwoFactorAuthentication::TokenStrategyManager)
        .to receive(:allow_remember_for_days)
        .and_return(0)

      # Log out and in again
      visit "/logout"
      expect_no_autologin

      # Enable functionality
      allow(OpenProject::TwoFactorAuthentication::TokenStrategyManager)
          .to receive(:allow_remember_for_days)
          .and_return(1)

      login_with_cookie
    end
  end
end
