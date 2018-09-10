#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Login', type: :feature do
  before do
    @capybara_ignore_elements = Capybara.ignore_hidden_elements
    Capybara.ignore_hidden_elements = true
  end

  after do
    Capybara.ignore_hidden_elements = @capybara_ignore_elements
    User.delete_all
    User.current = nil
  end

  def expect_being_logged_in(user)
    expect(page)
      .to have_selector("a[title='#{user.name}']")
  end

  def expect_not_being_logged_in
    expect(page)
      .to have_field('Login')
  end

  context 'sign in user' do
    let(:user_password) { 'bob' * 4 }
    let(:new_user_password) { 'obb' * 4 }
    let(:force_password_change) { false }
    let(:first_login) { false }
    let(:user) do
      FactoryBot.create(:user,
                        force_password_change: force_password_change,
                        first_login: first_login,
                        login: 'bob',
                        mail: 'bob@example.com',
                        firstname: 'Bo',
                        lastname: 'B',
                        password: user_password,
                        password_confirmation: user_password)
    end

    context 'with force password change' do
      let(:force_password_change) { true }
      let(:first_login) { true }

      it 'redirects to homescreen after forced password change
         (with validation error) and first login' do
        # first login
        login_with(user.login, user.password)
        expect(current_path).to eql signin_path

        # change password page (giving an invalid password)
        within('#main') do
          fill_in('password', with: user_password)
          fill_in('new_password', with: new_user_password)
          fill_in('new_password_confirmation', with: new_user_password + 'typo')
          click_link_or_button I18n.t(:button_save)
        end
        expect(current_path).to eql account_change_password_path

        # change password page
        within('#main') do
          fill_in('password', with: user_password)
          fill_in('new_password', with: new_user_password)
          fill_in('new_password_confirmation', with: new_user_password)
          click_link_or_button I18n.t(:button_save)
        end

        # on the my page
        expect(current_path).to eql '/'
      end
    end

    it 'prevents login for a blocked user' do
      user.lock!

      login_with(user.login, user.password)

      expect(current_path).to eql signin_path
      expect(page)
        .to have_content "Invalid user or password"
    end

    it 'forwards to the deep linked page after login' do
      visit my_page_path

      expect(page)
        .to have_field('Login')

      fill_in('Login', with: user.login)
      fill_in('Password', with: user_password)

      click_button(I18n.t(:button_login))

      expect(page)
        .to have_current_path my_page_path
    end

    context 'autologin',
            with_settings: {
              autologin: 1
            } do

      def fake_browser_closed
        page.driver.browser.set_cookie(OpenProject::Configuration['session_cookie_name'])
      end

      before do
        allow(Setting)
          .to receive(:autologin?)
          .and_return(true)
      end

      it 'logs in the user automatically if enabled' do
        login_with(user.login, user_password, autologin: true)

        fake_browser_closed
        visit home_path

        # expect being logged in automatically
        expect_being_logged_in(user)

        fake_browser_closed
        # faking having changed the autologin setting
        allow(Setting)
          .to receive(:autologin?)
          .and_return(false)
        visit my_page_path

        # expect not being logged in automatically
        expect_not_being_logged_in
      end
    end

    context 'with password expiry' do
      before do
        user.passwords.update_all(created_at: 31.days.ago,
                                  updated_at: 31.days.ago)
      end

      it 'does not allow login if the password is expired but the user can provide a new one' do
        login_with(user.login, user_password)

        expect_being_logged_in(user)
        visit signout_path

        allow(Setting)
          .to receive(:password_days_valid)
          .and_return(30)

        login_with(user.login, user_password)

        fill_in 'Current password', with: user_password
        fill_in 'New password', with: new_user_password
        fill_in 'Confirmation', with: new_user_password

        click_button 'Save'

        expect_being_logged_in(user)

        visit signout_path
        login_with(user.login, new_user_password)

        expect_being_logged_in(user)
      end
    end
  end
end
