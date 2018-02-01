#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'random password generation', type: :feature, js: true do
  let(:admin) { FactoryGirl.create :admin }
  let(:auth_source) { FactoryGirl.build :dummy_auth_source }
  let(:old_password) { 'old_Password!123' }
  let(:new_password) { 'new_Password!123' }
  let(:user) { FactoryGirl.create :user, password: old_password, password_confirmation: old_password }
  let(:user_page) { ::Pages::Admin::User.new(user.id) }

  before do
    login_with admin.login, 'adminADMIN!'
  end

  it 'can log in with a random generated password' do
    user_page.visit!

    expect(page).to have_selector('#user_password')
    expect(page).to have_selector('#user_password_confirmation')

    check 'user_assign_random_password'

    expect(page).to have_selector('#user_password[disabled]')
    expect(page).to have_selector('#user_password_confirmation[disabled]')

    # Remember password for login
    password = nil
    expect(OpenProject::Passwords::Generator)
      .to receive(:random_password)
      .and_wrap_original { |m, *args| password = m.call(*args) }

    click_on 'Save'

    expect(page).to have_selector('.flash', text: I18n.t(:notice_successful_update))
    expect(password).to be_present

    # Logout
    visit signout_path
    login_with user.login, password

    # Expect password change
    expect(page).to have_selector('#new_password')

    # Give wrong password
    fill_in 'password', with: old_password
    fill_in 'new_password', with: new_password
    fill_in 'new_password_confirmation', with: new_password
    click_on 'Save'

    expect(page).to have_content 'Invalid user or password'

    # Give correct password
    fill_in 'password', with: password
    fill_in 'new_password', with: new_password
    fill_in 'new_password_confirmation', with: new_password
    click_on 'Save'

    expect(page).to have_selector('.flash.notice', text: I18n.t(:notice_account_password_updated))

    # Logout and sign in with outdated password
    visit signout_path
    login_with user.login, password
    expect(page).to have_content 'Invalid user or password'

    # Logout and sign in with new_passworwd
    visit signout_path
    login_with user.login, new_password

    visit my_account_path
    expect(page).to have_selector('.account-menu-item.selected')
  end
end
