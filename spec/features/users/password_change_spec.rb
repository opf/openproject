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

RSpec.describe "random password generation", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }

  let(:old_password) { "old_Password!123" }
  let(:new_password) { "new_Password!123" }
  let(:user) { create(:user, password: old_password, password_confirmation: old_password) }
  let(:user_page) { Pages::Admin::Users::Edit.new(user.id) }

  describe "as admin user" do
    before do
      login_with admin.login, "adminADMIN!"
    end

    it "can log in with a random generated password" do
      user_page.visit!

      expect(page).to have_css("#user_password")
      expect(page).to have_css("#user_password_confirmation")

      check "user_assign_random_password"

      expect(page).to have_css("#user_password[disabled]")
      expect(page).to have_css("#user_password_confirmation[disabled]")

      # Remember password for login
      password = nil
      expect(OpenProject::Passwords::Generator)
        .to(receive(:random_password)
        .and_wrap_original { |m, *args| password = m.call(*args) })

      click_on "Save"

      expect(page).to have_css(".op-toast", text: I18n.t(:notice_successful_update))
      expect(password).to be_present

      # Logout
      visit signout_path
      login_with user.login, password

      # Expect password change
      expect(page).to have_css("#new_password")

      # Give wrong password
      fill_in "password", with: old_password
      fill_in "new_password", with: new_password
      fill_in "new_password_confirmation", with: new_password
      click_on "Save"

      expect(page).to have_content "Invalid user or password"

      # Give correct password
      fill_in "password", with: password
      fill_in "new_password", with: new_password
      fill_in "new_password_confirmation", with: new_password

      # Expect other sessions to be deleted
      session = Sessions::SqlBypass.new data: { user_id: user.id }, session_id: "other"
      session.save

      expect(Sessions::UserSession.for_user(user.id).count).to be >= 1

      click_on "Save"
      expect(page).to have_css(".op-toast.-info", text: I18n.t(:notice_account_password_updated))

      # The old session is removed
      expect(Sessions::UserSession.find_by(session_id: "other")).to be_nil

      # Logout and sign in with outdated password
      visit signout_path
      login_with user.login, password
      expect(page).to have_content "Invalid user or password"

      # Logout and sign in with new_passworwd
      visit signout_path
      login_with user.login, new_password

      visit my_account_path
      expect(page).to have_css(".account-menu-item.selected")
    end

    it "can configure and enforce password rules" do
      visit admin_settings_authentication_path
      expect_angular_frontend_initialized

      # Enforce rules
      # 3 of 'lowercase, uppercase, special'
      find(".form--check-box[value=uppercase]").set true
      find(".form--check-box[value=lowercase]").set true
      find(".form--check-box[value=numeric]").set false
      find(".form--check-box[value=special]").set true

      # Set min length to 4
      find_by_id("settings_password_min_length").set 4

      # Set min classes to 3
      find_by_id("settings_password_min_adhered_rules").set 3

      scroll_to_and_click(find(".button", text: "Save"))
      expect(page).to have_css(".op-toast.-success", text: I18n.t(:notice_successful_update))

      Setting.clear_cache

      expect(Setting.password_min_length).to eq(4)
      expect(Setting.password_min_adhered_rules).to eq(3)
      expect(Setting.password_active_rules).to eq(%w(uppercase lowercase special))

      # Go to user page
      user_page.visit!

      expect(page).to have_css("#user_password")
      expect(page).to have_css("#user_password_confirmation")

      # And I try to set my new password to "adminADMIN"
      fill_in "user_password", with: "adminADMIN"
      fill_in "user_password_confirmation", with: "adminADMIN"
      scroll_to_and_click(find(".button", text: "Save"))
      expect(page).to have_css(".errorExplanation", text: "Password Must contain characters of the following classes")

      # 2 of 3 classes
      fill_in "user_password", with: "adminADMIN123"
      fill_in "user_password_confirmation", with: "adminADMIN123"
      scroll_to_and_click(find(".button", text: "Save"))
      expect(page).to have_css(".errorExplanation", text: "Password Must contain characters of the following classes")

      # All classes
      fill_in "user_password", with: "adminADMIN!"
      fill_in "user_password_confirmation", with: "adminADMIN!"
      scroll_to_and_click(find(".button", text: "Save"))
      expect(page).to have_css(".op-toast.-success", text: I18n.t(:notice_successful_update))
    end
  end

  context "as a user on his my page" do
    let(:user_page) { Pages::My::PasswordPage.new }
    let(:third_password) { "third_Password!123" }

    before do
      login_as user
      user_page.visit!
    end

    context "with 2 of lowercase, uppercase, and numeric characters", :js, with_settings: {
      password_active_rules: %w(lowercase uppercase numeric),
      password_min_adhered_rules: 2,
      password_min_length: 4
    } do
      it "enforces those rules" do
        # Change to valid password according to spec
        user_page.change_password(old_password, "password")
        user_page.expect_password_weak_error_message

        # Change to valid password according to spec
        user_page.change_password(old_password, "Password")
        user_page.expect_password_updated_message
      end
    end

    it "enforces the former passwords count rule" do
      allow(Setting)
        .to receive(:[])
        .and_call_original

      # disabled
      allow(Setting)
        .to receive(:[])
        .with(:password_count_former_banned)
        .and_return(0)

      # user can reuse the old password
      user_page.change_password(old_password, old_password)
      user_page.expect_password_updated_message

      # Setting to two most recent passwords
      allow(Setting)
        .to receive(:[])
        .with(:password_count_former_banned)
        .and_return(2)

      user_page.change_password(old_password, old_password)
      user_page.expect_password_reuse_error_message(2)

      user_page.change_password(old_password, new_password)
      user_page.expect_password_updated_message

      user_page.change_password(new_password, old_password)
      user_page.expect_password_reuse_error_message(2)

      user_page.change_password(new_password, third_password)
      user_page.expect_password_updated_message
    end
  end
end
