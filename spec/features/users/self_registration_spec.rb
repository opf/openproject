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

RSpec.describe "user self registration", :js, :with_cuprite do
  let(:admin_password) { "Test123Test123" }
  let(:admin) { create(:admin, password: admin_password, password_confirmation: admin_password) }
  let(:home_page) { Pages::Home.new }

  context 'with "manual account activation"',
          with_settings: { self_registration: Setting::SelfRegistration.manual.to_s } do
    it "allows self registration on login page (Regression #28076)" do
      visit signin_path

      click_link "Create a new account"
      # deliberately inserting a wrong password confirmation
      within ".registration-modal" do
        fill_in "Username", with: "heidi"
        fill_in "First name", with: "Heidi"
        fill_in "Last name", with: "Switzerland"
        fill_in "Email", with: "heidi@heidiland.com"
        fill_in "Password", with: "test123=321test"
        fill_in "Confirmation", with: "test123=321test"

        click_button "Create"
      end

      expect(page)
        .to have_content("Your account was created and is now pending administrator approval.")
    end

    it "allows self registration and activation by an admin", :signout_via_visit do
      home_page.visit!

      # registration as an anonymous user
      within ".op-app-header" do
        click_link "Sign in"

        click_link "Create a new account"
      end

      # deliberately inserting a wrong password confirmation
      within ".registration-modal" do
        fill_in "Username", with: "heidi"
        fill_in "First name", with: "Heidi"
        fill_in "Last name", with: "Switzerland"
        fill_in "Email", with: "heidi@heidiland.com"
        fill_in "Password", with: "test123=321test"
        fill_in "Confirmation", with: "something different"

        click_button "Create"
      end

      expect(page)
        .to have_content("Password confirmation does not match password.")

      # correcting password
      within ".registration-modal" do
        # Cannot use 'Password' here as the error message on 'Confirmation' is part of the label
        # and contains the string 'Password' as well
        fill_in "user_password", with: "test123=321test"
        fill_in "Confirmation", with: "test123=321test"

        click_button "Create"
      end

      expect(page)
        .to have_content("Your account was created and is now pending administrator approval.")

      registered_user = User.find_by(status: Principal.statuses[:registered])

      # Trying unsuccessfully to login
      login_with "heidi", "test123=321test"

      expect(page)
        .to have_content I18n.t(:"account.error_inactive_manual_activation")

      # activation as admin
      login_with admin.login, admin_password

      user_page = Pages::Admin::Users::Edit.new(registered_user.id)

      user_page.visit!

      user_page.activate!

      expect(page)
        .to have_content("Successful update.")

      logout

      # Test logging in as newly created and activated user
      login_with "heidi", "test123=321test"

      within ".op-app-header" do
        expect(page)
          .to have_css("a[title='#{registered_user.name}']")
      end
    end
  end
end
