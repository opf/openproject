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

require_relative "../spec_helper"

RSpec.describe "Password change with OTP", :js, with_settings: {
  plugin_openproject_two_factor_authentication: {
    "active_strategies" => [:developer]
  }
} do
  let(:user_password) { "boB&" * 4 }
  let(:new_user_password) { "%obB" * 4 }
  let(:user) do
    create(:user,
           login: "bob",
           password: user_password,
           password_confirmation: user_password)
  end
  let(:expected_path_after_login) { home_path }

  def handle_password_change(requires_otp: true)
    visit signin_path
    within("#login-form") do
      fill_in("username", with: user.login)
      fill_in("password", with: user_password)
      click_link_or_button I18n.t(:button_login)
    end

    sms_token = nil
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(OpenProject::TwoFactorAuthentication::TokenStrategy::Developer)
      .to receive(:create_mobile_otp).and_wrap_original do |m|
      sms_token = m.call
    end
    # rubocop:enable RSpec/AnyInstance

    expect(page).to have_test_selector("change_password_header_title", text: I18n.t(:label_change_password))
    within("#content") do
      SeleniumHubWaiter.wait
      fill_in("password", with: user_password)
      fill_in("new_password", with: new_user_password)
      fill_in("new_password_confirmation", with: new_user_password)
      click_button I18n.t(:button_change_password)
    end

    if requires_otp
      expect(page).to have_css("input#otp")
      SeleniumHubWaiter.wait
      fill_in "otp", with: sms_token
      click_button I18n.t(:button_login), type: "submit"
    end

    expect(page).to have_current_path(expected_path_after_login, ignore_query: true)
  end

  context "when password is expired",
          with_settings: { password_days_valid: 7 } do
    before do
      user
    end

    context "when device present" do
      let!(:device) { create(:two_factor_authentication_device_sms, user:, default: true) }

      it "requires the password change after expired" do
        expect(user.current_password).not_to be_expired

        Timecop.travel(2.weeks.from_now) do
          expect(user.current_password).to be_expired
          handle_password_change

          user.reload
          expect(user.current_password).not_to be_expired
        end
      end
    end

    context "when no device present" do
      let!(:device) { nil }

      it "requires the password change after expired" do
        expect(user.current_password).not_to be_expired

        Timecop.travel(2.weeks.from_now) do
          expect(user.current_password).to be_expired
          handle_password_change(requires_otp: false)

          user.reload
          expect(user.current_password).not_to be_expired
        end
      end
    end
  end

  context "when force password change is set" do
    let(:user) do
      create(:user,
             force_password_change: true,
             first_login: true,
             login: "bob",
             password: user_password,
             password_confirmation: user_password)
    end
    let(:expected_path_after_login) { home_path }

    before do
      user
    end

    context "when device present" do
      let!(:device) { create(:two_factor_authentication_device_sms, user:, default: true) }

      it "requires the password change" do
        handle_password_change
      end
    end

    context "when no device present" do
      let!(:device) { nil }

      it "requires the password change without otp" do
        handle_password_change(requires_otp: false)
      end
    end
  end
end
