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

require 'spec_helper'
require 'features/projects/projects_page'

describe 'my', type: :feature, js: true do
  let(:current_user) { FactoryGirl.create :admin }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  context 'user' do
    it 'in settings they can edit their account details' do
      visit my_account_path

      fill_in 'user[mail]', with: 'foo@mail.com'
      fill_in 'user[firstname]', with: 'Foo'
      fill_in 'user[lastname]', with: 'Bar'
      click_on 'Save'

      expect(page).to have_content 'Account was successfully updated.'
      expect(current_path).to eq my_account_path

      u = User.find(current_user.id)
      expect(u.mail).to eq 'foo@mail.com'
      expect(u.firstname).to eq 'Foo'
      expect(u.lastname).to eq 'Bar'
    end

    it 'in Access Tokens they can reset their API key' do
      visit my_access_token_path
      find(:xpath, "//tr[contains(.,'API')]/td/a", text: 'Reset').click

      expect(page).to have_content 'Your API access key was reset.'
    end

    it 'in Access Tokens they can reset their RSS key' do
      visit my_access_token_path
      find(:xpath, "//tr[contains(.,'RSS')]/td/a", text: 'Reset').click

      expect(page).to have_content 'Your RSS access key was reset.'
    end
  end
end
