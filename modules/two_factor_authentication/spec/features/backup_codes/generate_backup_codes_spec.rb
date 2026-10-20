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

RSpec.describe "Generate 2FA backup codes", :js, with_config: { "2fa": { active_strategies: [:developer] } } do
  let(:user_password) { "bob!" * 4 }
  let(:user) do
    create(:user,
           login: "bob",
           password: user_password,
           password_confirmation: user_password)
  end
  let(:dialog) { Components::PasswordConfirmationDialog.new }

  before do
    login_as user
  end

  it "allows generating backup codes" do
    visit my_security_path

    # Log token for next access
    backup_codes = nil
    allow(TwoFactorAuthentication::BackupCode)
        .to receive(:regenerate!)
        .and_wrap_original do |m, user|
      backup_codes = m.call(user)
    end

    # Confirm with wrong password
    expect(page).to have_css(".Subhead-heading", text: I18n.t("two_factor_authentication.backup_codes.plural"))
    click_on I18n.t("two_factor_authentication.backup_codes.generate.title")
    dialog.confirm_flow_with "wrong_password", should_fail: true

    # Confirm with correct password
    expect(page).to have_css(".Subhead-heading", text: I18n.t("two_factor_authentication.backup_codes.plural"))
    click_on I18n.t("two_factor_authentication.backup_codes.generate.title")
    dialog.confirm_flow_with user_password, should_fail: false

    expect(page).to have_css(".op-toast.-warning")
    backup_codes.each do |code|
      expect(page).to have_css(".two-factor-authentication--backup-codes li", text: code)
    end
  end
end
