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
require_relative "shared_two_factor_examples"

RSpec.describe "activating an invited account",
               :js,
               with_settings: {
                 plugin_openproject_two_factor_authentication: { "active_strategies" => [:developer] }
               } do
  include SharedTwoFactorExamples

  let(:user) do
    user = build(:user, first_login: true)
    UserInvitation.invite_user! user

    user
  end
  let(:token) { Token::Invitation.find_by(user_id: user.id) }

  def activate!
    visit url_for(controller: :account,
                  action: :activate,
                  token: token.value,
                  only_path: true)

    expect(page).to have_current_path account_register_path

    fill_in I18n.t("attributes.password"), with: "Password1234"
    fill_in I18n.t("activerecord.attributes.user.password_confirmation"), with: "Password1234"

    click_button I18n.t(:button_create)
  end

  context "when not enforced and no device present" do
    it "redirects to active" do
      activate!

      visit my_account_path

      within_test_selector "my-account-form" do
        expect(page).to have_field "user_login", with: user.login
      end
    end
  end

  context "when not enforced, but device present" do
    let!(:device) { create(:two_factor_authentication_device_sms, user:, default: true) }

    it "requests a OTP" do
      sms_token = nil
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(OpenProject::TwoFactorAuthentication::TokenStrategy::Developer)
          .to receive(:create_mobile_otp).and_wrap_original do |m|
        sms_token = m.call
      end
      # rubocop:enable RSpec/AnyInstance

      activate!
      expect_flash(message: "Developer strategy generated the following one-time password:")

      fill_in I18n.t(:field_otp), with: sms_token
      click_button I18n.t(:button_login), type: "submit"
      wait_for_network_idle

      visit my_account_path

      within_test_selector "my-account-form" do
        expect(page).to have_field "user_login", with: user.login
      end
    end

    it "handles faulty user input on two factor authentication" do
      activate!

      expect_flash(message: "Developer strategy generated the following one-time password:")

      fill_in I18n.t(:field_otp), with: "asdf" # faulty token
      click_button I18n.t(:button_login), type: "submit"

      expect(page).to have_current_path signin_path
      expect(page).to have_content(I18n.t(:notice_account_otp_invalid))
    end
  end

  context "when enforced",
          with_settings: {
            plugin_openproject_two_factor_authentication: {
              "active_strategies" => [:developer],
              "enforced" => true
            }
          } do
    before do
      activate!
    end

    it_behaves_like "create enforced sms device"
  end
end
