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

RSpec.describe "user deletion:", :js, :selenium, driver: :firefox_en do
  let(:dialog) { Components::PasswordConfirmationDialog.new }

  include Flash::Expectations

  before do
    page.set_rack_session(user_id: current_user.id, updated_at: Time.now)
  end

  context "regular user" do
    let(:user_password) { "bob!" * 4 }
    let(:current_user) do
      create(:user,
             password: user_password,
             password_confirmation: user_password)
    end

    it "can delete their own account", :signout_via_visit, with_settings: { users_deletable_by_self: true } do
      visit my_account_path
      page.find_test_selector("delete-my-account-button").click

      check "I understand that this deletion cannot be reversed."
      click_on "Delete permanently"

      dialog.confirm_flow_with user_password

      expect(page).to have_content("Account has been scheduled for deletion. " \
                                   "Note that this process takes place in the background. " \
                                   "It might take a few moments until the user is fully deleted.")
      expect(page).to have_current_path "/login"
    end

    it "cannot delete their own account if the settings forbid it", with_settings: { users_deletable_by_self: false } do
      visit my_account_path

      expect(page).not_to have_test_selector("delete-my-account-button")
    end
  end

  context "user with global add role" do
    let!(:user) { create(:user) }
    let(:current_user) { create(:user, global_permissions: %i[manage_user view_all_principals]) }

    it "can not delete even if settings allow it", with_settings: { users_deletable_by_admins: true } do
      visit edit_user_path(user)

      expect(page).to have_content "#{user.firstname} #{user.lastname}"
      expect(page).to have_no_content "Delete account"

      visit deletion_info_user_path(user)
      expect(page).to have_text "Error 404"
    end
  end

  context "admin user" do
    let!(:user) { create(:user) }
    let(:user_password) { "admin! * 4" }
    let(:current_user) do
      create(:admin,
             password: user_password,
             password_confirmation: user_password)
    end

    it "can delete other users if the setting permits it", with_settings: { users_deletable_by_admins: true } do
      visit edit_user_path(user)

      expect(page).to have_content "#{user.firstname} #{user.lastname}"

      click_on "Delete"

      SeleniumHubWaiter.wait
      check "I understand that this deletion cannot be reversed."
      click_on "Delete permanently"

      dialog.confirm_flow_with "wrong", should_fail: true

      click_on "Delete"
      SeleniumHubWaiter.wait
      check "I understand that this deletion cannot be reversed."
      click_on "Delete permanently"

      dialog.confirm_flow_with user_password, should_fail: false

      expect(page).to have_content("Account has been scheduled for deletion. " \
                                   "Note that this process takes place in the background. " \
                                   "It might take a few moments until the user is fully deleted.")
      expect(page).to have_current_path "/users"
    end

    it "can delete and confirm with keyboard (Regression #44499)", with_settings: { users_deletable_by_admins: true } do
      visit edit_user_path(user)

      expect(page).to have_content "#{user.firstname} #{user.lastname}"

      click_on "Delete"

      SeleniumHubWaiter.wait
      check "I understand that this deletion cannot be reversed."
      click_on "Delete permanently"

      dialog.confirm_flow_with user_password, with_keyboard: true, should_fail: false

      expect(page).to have_content("Account has been scheduled for deletion. " \
                                   "Note that this process takes place in the background. " \
                                   "It might take a few moments until the user is fully deleted.")
      expect(page).to have_current_path "/users"
    end

    it "cannot delete other users if the settings forbid it", with_settings: { users_deletable_by_admins: false } do
      visit edit_user_path(user)

      expect(page).to have_no_content "Delete account"
    end

    it "can change the deletablilty settings" do
      Setting.users_deletable_by_admins = 0
      Setting.users_deletable_by_self = 0

      visit admin_settings_users_path

      find_by_id("settings_users_deletable_by_admins").set(true)
      find_by_id("settings_users_deletable_by_self").set(true)

      click_on "Save"

      expect_flash message: "Successful update."

      expect(Setting.users_deletable_by_admins?).to be true
      expect(Setting.users_deletable_by_self?).to be true
    end
  end
end
