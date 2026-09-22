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

RSpec.describe "OmniAuth POST login", :js do
  OpenProject::Hooks::ViewAccountLoginAuthProvider

  let(:user_menu) { Components::UserMenu.new }

  let(:user) do
    create(:user,
           force_password_change: false,
           firstname: "omni",
           lastname: "bob",
           mail: "omnibob@example.com")
  end

  it "signs in through the auto-submit form" do
    visit signin_path

    expect(page).to have_link("Omniauth Developer", href: %r{/login/omniauth/developer})

    within "#login-form" do
      click_link "Omniauth Developer"
    end

    fill_in "first_name", with: user.firstname
    fill_in "last_name", with: user.lastname
    fill_in "email", with: user.mail
    click_button "Sign In"

    user_menu.expect_user_shown "omni bob"
  end

  context "with direct login",
          with_settings: { omniauth_direct_login_provider: "developer" } do
    it "auto-submits a POST form to the provider" do
      visit signin_path

      expect(page).to have_field("first_name")
      expect(page).to have_no_css("#omniauth-direct-login-form")
    end
  end
end
