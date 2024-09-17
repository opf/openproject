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

RSpec.describe "layouts/base" do
  # This is to make `visit` available. It might be already included by the time
  # we reach this spec, but for running this spec alone we need it here. Best
  # of both worlds.
  include Capybara::DSL
  include Capybara::RSpecMatchers

  include Redmine::MenuManager::MenuHelper
  helper Redmine::MenuManager::MenuHelper
  let(:user) { build_stubbed(:user) }
  let(:anonymous) { build_stubbed(:anonymous) }

  before do
    without_partial_double_verification do
      allow(view).to receive(:default_breadcrumb)
      allow(controller).to receive(:default_search_scope)
      allow(view).to receive(:render_to_string)
      allow(view).to receive_messages(current_menu_item: "overview", current_user:)
    end

    allow(User).to receive(:current).and_return current_user
  end

  describe "Sign in button" do
    let(:current_user) { anonymous }

    before do
      render
    end

    context "with omni_auth_direct_login disabled" do
      it "shows the login drop down menu" do
        expect(rendered).to have_css("div#nav-login-content", visible: false)
      end
    end

    context "with omni_auth_direct_login enabled",
            with_config: { omniauth_direct_login_provider: "some_provider" } do
      it "shows just a sign-in link, no menu" do
        expect(rendered).to have_css "a[href='/login']"
        expect(rendered).to have_no_css "div#nav-login-content"
      end
    end
  end

  describe "login form" do
    let(:current_user) { anonymous }

    context "with password login enabled" do
      before do
        render
      end

      it "shows a login form" do
        expect(rendered).to include "Username"
        expect(rendered).to include "Password"
      end
    end

    context "with password login disabled" do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
        render
      end

      it "shows no password login form" do
        expect(rendered).not_to include "Username"
        expect(rendered).not_to include "Password"
      end
    end
  end

  describe "icons" do
    let(:current_user) { anonymous }

    context "not in development environment" do
      before do
        render
      end

      it "renders main favicon" do
        expect(rendered).to have_css(
          "link[type='image/x-icon'][href*='/assets/favicon.ico']",
          visible: false
        )
      end

      it "renders apple icons" do
        expect(rendered).to have_css(
          "link[type='image/png'][href*='/assets/apple-touch-icon-120x120.png']",
          visible: false
        )
      end

      # We perform a get request against the icons to ensure they are there (and
      # avoid 404 errors in production). Should you continue to see 404s in production,
      # ensure your asset cache is not stale.

      # We do this here as opposed to a request spec to 1. keep icon specs contained
      # in one place, and 2. the view itself makes this request, so this is an appropriate
      # location for it.
      it "icons actually exist" do
        visit "assets/favicon.ico"
        expect(page.status_code).to eq(200)

        visit "assets/apple-touch-icon-120x120.png"
        expect(page.status_code).to eq(200)
      end
    end

    context "in development environment" do
      before do
        allow(OpenProject::Configuration).to receive(:development_highlight_enabled?).and_return(true)

        render
      end

      it "renders main favicon" do
        expect(rendered).to have_css(
          "link[type='image/x-icon'][href*='/assets/development/favicon.ico']",
          visible: false
        )
      end

      it "renders apple icons" do
        expect(rendered).to have_css(
          "link[type='image/png'][href*='/assets/development/apple-touch-icon-120x120.png']",
          visible: false
        )
      end

      it "icons actually exist" do
        visit "assets/development/favicon.ico"
        expect(page.status_code).to eq(200)

        visit "assets/development/apple-touch-icon-120x120.png"
        expect(page.status_code).to eq(200)
      end
    end
  end

  describe "highlighting styles", with_config: { rails_asset_host: "foo.bar.com" } do
    let(:current_user) { anonymous }

    before do
      allow(FrontendAssetHelper).to receive(:assets_proxied?).and_return(false)

      render
    end

    it "is referenced without the asset host" do
      expect(rendered).to include('href="http://foo.bar.com/assets/')
      expect(rendered).to include('href="/highlighting/styles/')
    end
  end

  describe "inline custom styles" do
    let(:a_token) { EnterpriseToken.new }
    let(:current_user) { anonymous }

    context "EE is active and styles are present" do
      let(:custom_style) { create(:custom_style) }
      let(:primary_color) { create(:"design_color_primary-button-color") }

      before do
        allow(EnterpriseToken).to receive(:allows_to?).with(:define_custom_style).and_return(true)
        allow(CustomStyle).to receive(:current).and_return(custom_style)
      end

      it "contains inline CSS block with those styles." do
        render
        expect(rendered).to render_template partial: "custom_styles/_inline_css"
      end

      it "renders CSS4 variables" do
        primary_color
        render
        expect(rendered).to render_template partial: "custom_styles/_inline_css"
        expect(rendered).to match /--primary-button-color:\s*#{primary_color.hexcode}/
      end
    end

    context "EE is active and styles are not present" do
      before do
        allow(EnterpriseToken).to receive(:current).and_return(a_token)
        allow(a_token).to receive(:expired?).and_return(false)
        allow(a_token).to receive(:allows_to?).with(:define_custom_style).and_return(true)
        allow(CustomStyle).to receive(:current).and_return(nil)

        render
      end

      it "does not contain an inline CSS block for styles." do
        expect(rendered).not_to render_template partial: "custom_styles/_inline_css"
      end
    end

    context "EE does not allow custom styles" do
      before do
        allow(EnterpriseToken).to receive(:current).and_return(a_token)
        allow(a_token).to receive(:expired?).and_return(false)
        allow(a_token).to receive(:allows_to?).with(:define_custom_style).and_return(false)

        render
      end

      it "does not contain an inline CSS block for styles." do
        expect(rendered).not_to render_template partial: "custom_styles/_inline_css"
      end
    end

    context "no EE present" do
      before do
        allow(EnterpriseToken).to receive(:current).and_return(nil)

        render
      end

      it "does not contain an inline CSS block for styles." do
        expect(rendered).not_to render_template partial: "custom_styles/_inline_css"
      end
    end
  end

  describe "current user meta tag" do
    before do
      render
    end

    context "with the user being logged in" do
      let(:current_user) { user }

      it "has a current_user metatag" do
        expect(rendered).to have_css("meta[name=current_user]", visible: false)
      end
    end

    context "with the user being anonymous" do
      let(:current_user) { anonymous }

      it "has a current_user metatag" do
        expect(rendered).to have_css("meta[name=current_user]", visible: false)
      end
    end
  end

  describe "openproject_initializer meta tag" do
    let(:current_user) { anonymous }
    let(:base) { "meta[name=openproject_initializer]" }

    before do
      render
    end

    it "has the meta tag" do
      expect(rendered).to have_selector(base, visible: false)
    end
  end
end
