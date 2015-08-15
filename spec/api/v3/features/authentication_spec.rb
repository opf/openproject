#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Login', type: :feature do
  after do
    User.current = nil
    enable_test_auth_protection
  end

  let(:user_password) { 'bob1!' * 4 }
  let(:user) do
    FactoryGirl.create(:user,
                       force_password_change: false,
                       first_login: false,
                       login: 'bob',
                       mail: 'bob@example.com',
                       firstname: 'Bo',
                       lastname: 'B',
                       password: user_password,
                       password_confirmation: user_password,
                      )
  end

  let(:other_user) { FactoryGirl.create(:user) }

  it 'enforces the current user to be set correctly on each api request' do
    # login to set the session
    visit signin_path
    within('#login-form') do
      fill_in('username', with: user.login)
      fill_in('password', with: user_password)
      click_link_or_button I18n.t(:button_login)
    end

    # simulate another user having used the process
    # which would cause User.current to be set
    User.current = other_user

    # disable a hack in the API's authenticate method
    # which would cause authentication to not work
    disable_test_auth_protection

    # taking /api/v3 as it does not run any authorization
    visit '/api/v3'
    expect(User.current).to eql(user)
  end

  def disable_test_auth_protection
    ENV['CAPYBARA_DISABLE_TEST_AUTH_PROTECTION'] = 'true'
  end

  def enable_test_auth_protection
    ENV.delete 'CAPYBARA_DISABLE_TEST_AUTH_PROTECTION'
  end
end
