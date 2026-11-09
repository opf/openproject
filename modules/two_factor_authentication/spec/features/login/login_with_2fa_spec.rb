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

RSpec.describe "Login with 2FA device",
               :js,
               with_settings: {
                 plugin_openproject_two_factor_authentication: {
                   "active_strategies" => [:developer]
                 }
               } do
  include SharedTwoFactorExamples
  let(:user_password) { "bob!" * 4 }
  let(:user) do
    create(:user,
           login: "bob",
           password: user_password,
           password_confirmation: user_password)
  end

  context "with a default device" do
    let!(:device) { create(:two_factor_authentication_device_sms, user:, active: true, default: true) }

    it "requests a 2FA" do
      sms_token = nil
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(OpenProject::TwoFactorAuthentication::TokenStrategy::Developer)
        .to receive(:create_mobile_otp).and_wrap_original do |m|
        sms_token = m.call
      end
      # rubocop:enable RSpec/AnyInstance

      first_login_step
      two_factor_step(sms_token)
      expect_logged_in
    end

    it "returns to 2FA page if invalid" do
      first_login_step
      two_factor_step("whatever")

      expect_flash(type: :error, message: I18n.t(:notice_account_otp_invalid))
      expect(page).to have_current_path signin_path
    end
  end
end
