#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'edit users', type: :feature, js: true do
  shared_let(:admin) { FactoryBot.create :admin }
  let(:current_user) { admin }
  let(:user) { FactoryBot.create :user, mail: 'foo@example.com' }

  let!(:auth_source) { FactoryBot.create :auth_source }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  def auth_select
    find :css, 'select#user_auth_source_id'
  end

  def user_password
    find :css, 'input#user_password'
  end

  context 'with internal authentication' do
    before do
      visit edit_user_path(user)
    end

    it 'shows internal authentication being selected including password settings' do
      expect(auth_select.value).to eq '' # selected internal
      expect(user_password).to be_visible
    end

    it 'hides password settings when switching to an LDAP auth source' do
      auth_select.select auth_source.name

      expect(page).not_to have_selector('input#user_password')
    end
  end

  context 'with external authentication' do
    before do
      user.auth_source = auth_source
      user.save!

      visit edit_user_path(user)
    end

    it 'shows external authentication being selected and no password settings' do
      expect(auth_select.value).to eq auth_source.id.to_s
      expect(page).not_to have_selector('input#user_password')
    end

    it 'shows password settings when switching back to internal authentication' do
      auth_select.select I18n.t('label_internal')

      expect(user_password).to be_visible
    end
  end

  context 'as global user' do
    shared_let(:global_manage_user) { FactoryBot.create :user, global_permission: :manage_user }
    let(:current_user) { global_manage_user }

    it 'can too edit the user' do
      visit edit_user_path(user)

      expect(page).to have_no_selector('.admin-overview-menu-item', text: 'Overview')
      expect(page).to have_no_selector('.users-and-permissions-menu-item', text: 'Users & Permissions')
      expect(page).to have_selector('.users-menu-item.selected', text: 'Users')

      expect(page).to have_selector 'select#user_auth_source_id'
      expect(page).to have_no_selector 'input#user_password'

      expect(page).to have_selector '#user_login'
      expect(page).to have_selector '#user_firstname'
      expect(page).to have_selector '#user_lastname'
      expect(page).to have_selector '#user_mail'

      fill_in 'user[firstname]', with: 'NewName', fill_options: { clear: :backspace }
      select auth_source.name, from: 'user[auth_source_id]'

      click_on 'Save'

      expect(page).to have_selector('.flash.notice', text: 'Successful update.')

      user.reload

      expect(user.firstname).to eq 'NewName'
      expect(user.auth_source).to eq auth_source
    end

    it 'can reinvite the user' do
      visit edit_user_path(user)

      click_on 'Send invitation'

      expect(page).to have_selector('.flash.notice', text: 'An invitation has been sent to foo@example.com')
    end
  end
end
