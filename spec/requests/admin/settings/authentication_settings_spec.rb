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

RSpec.describe "Authentication Settings",
               :skip_csrf,
               type: :rails_request do
  let(:admin) { create(:admin) }

  before do
    login_as(admin)
  end

  describe "GET /admin/settings/authentication?tab=passwords" do
    context "with password login enabled" do
      before do
        get "/admin/settings/authentication.html?tab=passwords"
      end

      it "shows password settings" do
        expect(response).to have_http_status(:success)

        expect(page).to have_field(I18n.t(:setting_lost_password), disabled: false)
        expect(page).to have_field(I18n.t(:setting_brute_force_block_after_failed_logins), disabled: false)
      end
    end

    context "with password login disabled", with_settings: { password_login: "none" } do
      before do
        get "/admin/settings/authentication.html?tab=passwords"
      end

      it "disables password settings" do
        expect(response).to have_http_status(:success)

        expect(page).to have_field(I18n.t(:setting_lost_password), disabled: true)
        expect(page).to have_field(I18n.t(:setting_brute_force_block_after_failed_logins), disabled: true)
      end
    end
  end

  describe "GET /admin/settings/authentication?tab=sso", with_ee: %i[sso_auth_providers] do
    let!(:provider) { create(:oidc_provider) }
    let!(:bypass_user) { create(:user, login: "breakglass") }

    before do
      Setting.password_login = "except_sso"
      Setting.password_login_bypass_principal_ids = [bypass_user.id.to_s]
      get "/admin/settings/authentication.html?tab=sso"
    end

    it "shows the password login policy" do
      expect(response).to have_http_status(:success)

      expect(page).to have_field(I18n.t(:setting_password_login_except_sso), disabled: false)
      expect(page).to have_link("/login/internal", href: internal_signin_path)
    end

    it "preselects the exempt principals" do
      input_value = page.find("opce-user-autocompleter")["data-input-value"]

      expect(JSON.parse(input_value)).to eq [bypass_user.id]
    end

    it "shows the bypass principals only when password login is disallowed" do
      expect(page).to have_css("opce-user-autocompleter", visible: :visible)

      Setting.password_login = "all"
      get "/admin/settings/authentication.html?tab=sso"

      expect(page).to have_no_css("opce-user-autocompleter", visible: :visible)
    end

    it "explains the bypass principals" do
      expect(page).to have_text(
        "Even when password login in disabled, these users and groups will be able to use their password to sign in."
      )
    end
  end

  describe "GET /admin/settings/authentication?tab=sso without an SSO provider",
           with_ee: %i[sso_auth_providers] do
    before do
      Setting.password_login = "except_sso"
      get "/admin/settings/authentication.html?tab=sso"
    end

    it "warns that password login restrictions are unavailable" do
      expect(page).to have_text("Password login restrictions are unavailable because no SSO provider is currently enabled.")
    end

    it "disables the password login settings" do
      expect(page).to have_select(
        I18n.t(:setting_omniauth_direct_login_provider),
        disabled: true
      )
      expect(Setting.omniauth_direct_login_provider).to be_blank
      expect(page).to have_field(I18n.t(:setting_password_login_all), disabled: true)
      expect(page).to have_field(I18n.t(:setting_password_login_except_sso), disabled: true)
      expect(page.find("opce-user-autocompleter", visible: :visible)["data-disabled"]).to eq "true"
    end
  end

  describe "GET /admin/settings/authentication?tab=sso with password login configured by the environment",
           :settings_reset,
           with_ee: %i[sso_auth_providers],
           with_env: { "OPENPROJECT_DISABLE__PASSWORD__LOGIN" => "true" } do
    let!(:provider) { create(:oidc_provider) }

    before do
      reset(:disable_password_login)
      reset(:password_login)
      get "/admin/settings/authentication.html?tab=sso"
    end

    it "shows that the setting cannot be edited" do
      expect(page).to have_text(
        "The following settings are configured through the environment and cannot be edited here:"
      )
      expect(page).to have_css("li", exact_text: "Password login")
    end

    it "disables the password login group" do
      expect(page).to have_field(I18n.t(:setting_password_login_none), disabled: true, checked: true)
      expect(page.find("opce-user-autocompleter", visible: :visible)["data-disabled"]).to eq "false"
    end
  end

  describe "GET /admin/settings/authentication?tab=sso with multiple settings configured by the environment",
           with_ee: %i[sso_auth_providers] do
    let!(:provider) { create(:oidc_provider) }
    let!(:bypass_user) { create(:user) }

    before do
      Setting.password_login = "except_sso"
      Setting.password_login_bypass_principal_ids = [bypass_user.id.to_s]
      allow(Setting).to receive_messages(
        password_login_writable?: false,
        password_login_bypass_principal_ids_writable?: false
      )

      get "/admin/settings/authentication.html?tab=sso"
    end

    it "disables the bypass principal inputs and shows the environment banner" do
      expect(page.find("opce-user-autocompleter", visible: :visible)["data-disabled"]).to eq "true"
      expect(page).to have_css(
        'input[name="settings[password_login_bypass_principal_ids][]"][disabled]',
        visible: :all
      )
      expect(page).to have_text("The following settings are configured through the environment and cannot be edited here:")
      expect(page).to have_css("li", exact_text: "Password login")
      expect(page).to have_css("li", exact_text: "Users and groups who may still use a password")
    end
  end

  describe "PATCH /admin/settings/authentication?tab=passwords" do
    context "when all password requirement checkboxes are unchecked" do
      before do
        Setting.password_active_rules = %w[lowercase uppercase]
        patch "/admin/settings/authentication.html?tab=passwords",
              params: { settings: { password_active_rules: [""] } }
      end

      it "saves an empty list of active rules" do
        expect(Setting.password_active_rules).to eq([])
      end
    end
  end
end
