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
require 'features/projects/projects_page'

describe 'edit users', type: :feature, js: true do
  let(:current_user) { FactoryGirl.create :admin }
  let(:user) { FactoryGirl.create :user }

  let!(:auth_source) { FactoryGirl.create :auth_source }

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
end
