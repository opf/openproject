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

RSpec.describe "Login with 2FA backup code",
               :js,
               with_settings: {
                 plugin_openproject_two_factor_authentication: { "active_strategies" => [:developer] }
               } do
  include SharedTwoFactorExamples

  let(:user_password) { "bob!" * 4 }
  let(:user) do
    create(:user,
           login: "bob",
           password: user_password,
           password_confirmation: user_password)
  end
  let!(:device) { create(:two_factor_authentication_device_sms, user:, active: true, default: true) }

  context "when user has no backup code" do
    it "does not show the backup code link" do
      first_login_step

      # Open other options
      find_by_id("toggle_resend_form").click
      expect(page).to have_no_css("a", text: I18n.t("two_factor_authentication.login.enter_backup_code_title"))
    end
  end

  context "when user has backup codes" do
    let!(:valid_backup_codes) { TwoFactorAuthentication::BackupCode.regenerate! user }

    it "allows entering a backup code" do
      expect(valid_backup_codes.length).to eq(10)

      first_login_step
      expect(page).to have_css("#toggle_resend_form", wait: 10)

      # Open other options
      # This may fail on the first request when the assets aren't ready yet
      SeleniumHubWaiter.wait
      find_by_id("toggle_resend_form").click
      SeleniumHubWaiter.wait
      find("a", text: I18n.t("two_factor_authentication.login.enter_backup_code_title"), wait: 2).click

      expect(page).to have_css("h2", text: I18n.t("two_factor_authentication.login.enter_backup_code_title"))
      SeleniumHubWaiter.wait
      fill_in "backup_code", with: "whatever"
      click_on "Submit"

      # Expect failure
      expect_flash(type: :error, message: I18n.t("two_factor_authentication.error_invalid_backup_code"))
      expect(page).to have_current_path signin_path

      # Try again!
      first_login_step
      SeleniumHubWaiter.wait
      find_by_id("toggle_resend_form").click
      SeleniumHubWaiter.wait
      find("a", text: I18n.t("two_factor_authentication.login.enter_backup_code_title")).click

      expect(page).to have_css("h2", text: I18n.t("two_factor_authentication.login.enter_backup_code_title"))
      SeleniumHubWaiter.wait
      fill_in "backup_code", with: valid_backup_codes.first
      click_on "Submit"

      expect_logged_in
    end
  end
end
