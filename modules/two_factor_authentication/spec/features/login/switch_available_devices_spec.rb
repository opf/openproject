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

RSpec.describe "Login by switching 2FA device",
               :js,
               with_settings: {
                 plugin_openproject_two_factor_authentication: { "active_strategies" => %i[developer totp] }
               } do
  include SharedTwoFactorExamples

  let(:user_password) { "bob!" * 4 }
  let(:user) do
    create(:user,
           login: "bob",
           password: user_password,
           password_confirmation: user_password)
  end

  context "with two default device" do
    let!(:device) { create(:two_factor_authentication_device_sms, user:, active: true, default: true) }
    let!(:device2) { create(:two_factor_authentication_device_totp, user:, active: true, default: false) }

    it "requests a 2FA and allows switching" do
      first_login_step

      expect(page).to have_css("input#otp")

      # Toggle device to TOTP
      find_by_id("toggle_resend_form").click

      find(".button--link[value='#{device2.redacted_identifier}']").click
      wait_for_network_idle

      expect(page).to have_css("input#otp")
      expect(page).to have_css("#submit_otp p", text: device2.redacted_identifier)

      two_factor_step(device2.totp.now)
      expect_logged_in
    end
  end
end
