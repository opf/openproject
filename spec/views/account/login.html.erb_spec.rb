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

RSpec.describe "account/login" do
  context "with password login enabled" do
    before do
      render
    end

    it "shows a login field" do
      expect(rendered).to include "Password"
    end
  end

  context "with a custom application title" do
    before do
      allow(Setting).to receive(:app_title).and_return("Acme Projects")
      render
    end

    it "shows the instance name in the heading" do
      expect(rendered).to include "Sign in to Acme Projects"
    end
  end

  context "with autologin and self registration enabled" do
    before do
      allow(Setting::Autologin).to receive(:enabled?).and_return(true)
      allow(Setting).to receive(:self_registration)
        .and_return(Setting::SelfRegistration.value(key: :activation_by_email))
      render
    end

    it "puts the autologin checkbox and the lost password link on one row" do
      row = Capybara.string(rendered).find(".FormControl-horizontalGroup")

      expect(row).to have_field("autologin", type: "checkbox")
      expect(row).to have_link(I18n.t(:label_password_lost), href: account_lost_password_path)
    end

    it "renders a full width submit button" do
      expect(rendered).to have_button(I18n.t(:button_login), type: "submit", class: "Button--fullWidth")
    end

    it "renders the registration link in its own section below the form" do
      prompt = Capybara.string(rendered).find(".account-prompt")

      expect(prompt).to have_css("h3", text: I18n.t("account.no_account_yet"))
      expect(prompt).to have_link(I18n.t(:label_register), href: account_register_path)
    end
  end

  context "with external authentication providers" do
    before do
      allow(view).to receive(:call_hook).and_call_original
      allow(view).to receive(:call_hook)
        .with(:view_account_login_auth_provider)
        .and_return(%(<a class="auth-provider" href="/auth/google">Google</a>).html_safe)
      render
    end

    it "renders the providers below a titled external account section" do
      expect(rendered).to have_css(".login-auth-providers h3",
                                   text: I18n.t("account.login_with_external_account"))
      expect(rendered).to have_css(".login-auth-provider-list a.auth-provider", text: "Google")
    end
  end

  context "when the auth provider hook renders nothing but view annotations" do
    before do
      allow(Rails.env).to receive(:development?).and_return(true)
      allow(view).to receive(:call_hook).and_call_original
      allow(view).to receive(:call_hook)
        .with(:view_account_login_auth_provider)
        .and_return("<!-- BEGIN hooks/login/_auth_provider -->\n<!-- END hooks/login/_auth_provider -->".html_safe)
      render
    end

    it "does not render the external account section" do
      expect(rendered).to have_no_css(".login-auth-providers")
    end
  end

  context "with self registration disabled" do
    before do
      allow(Setting).to receive(:self_registration).and_return(Setting::SelfRegistration.disabled)
      render
    end

    it "does not render the registration section" do
      expect(rendered).to have_no_css(".account-prompt")
    end
  end

  context "with password login disabled" do
    before do
      allow(Setting).to receive(:password_login).and_return("none")
      render
    end

    it "does not show a login field" do
      expect(rendered).not_to include "Password"
    end
  end

  context "with password login disabled on the internal login page" do
    before do
      allow(Setting).to receive(:password_login).and_return("none")
      assign(:force_password_login_form, true)
      render
    end

    it "shows a login field" do
      expect(rendered).to include "Password"
    end
  end

  context "if user is not logged in" do
    before do
      User.anonymous.pref.update(settings: { "theme" => "sync_with_os" })
    end

    it "uses the OS-synced theme preference by default" do
      theme_data = view.user_theme_data_attributes

      expect(theme_data[:auto_theme_switcher_theme_value]).to eq("sync_with_os")
      # Check that contrast flags exist
      expect(theme_data).to have_key(:auto_theme_switcher_force_light_contrast_value)
      expect(theme_data).to have_key(:auto_theme_switcher_force_dark_contrast_value)
      # Check logo classes
      expect(theme_data[:auto_theme_switcher_desktop_light_high_contrast_logo_class]).to eq("op-logo--link_high_contrast")
      expect(theme_data[:auto_theme_switcher_mobile_white_logo_class]).to eq("op-logo--icon_white")
    end
  end
end
