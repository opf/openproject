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

  context 'sign in user' do
    let(:user_password) { 'bob' * 4 }
    let(:new_user_password) { 'obb' * 4 }
    let(:user) do
      FactoryBot.create(:user,
                        force_password_change: true,
                        first_login: true,
                        login: 'bob',
                        mail: 'bob@example.com',
                        firstname: 'Bo',
                        lastname: 'B',
                        password: user_password,
                        password_confirmation: user_password)
    end

    it 'redirects to homescreen after forced password change
       (with validation error) and first login' do
      # first login
      visit signin_path
      within('#login-form') do
        fill_in('username', with: user.login)
        fill_in('password', with: user_password)
        click_link_or_button I18n.t(:button_login)
      end
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
end
