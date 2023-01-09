#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

describe 'Admin menu items', js: true do
  let(:user) { create :admin }

  before do
    login_as user
  end

  after do
    OpenProject::Configuration['hidden_menu_items'] = []
  end

  context 'without having any menu items hidden in configuration' do
    it 'must display all menu items' do
      visit admin_index_path

      expect(page).to have_selector('[data-qa-selector="menu-blocks--container"]')
      expect(page).to have_selector('[data-qa-selector="menu-block"]', count: 20)
      expect(page).to have_selector('[data-qa-selector="op-menu--item-action"]', count: 21) # All plus 'overview'
    end
  end

  context 'with having custom hidden menu items',
          with_config: {
            'hidden_menu_items' => { 'admin_menu' => ['colors'] }
          } do
    it 'must not display the hidden menu items and blocks' do
      visit admin_index_path

      expect(page).to have_selector('[data-qa-selector="menu-blocks--container"]')
      expect(page).to have_selector('[data-qa-selector="menu-block"]', count: 19)
      expect(page).not_to have_selector('[data-qa-selector="menu-block"]', text: I18n.t('timelines.admin_menu.colors'))

      expect(page).to have_selector('[data-qa-selector="op-menu--item-action"]', count: 20) # All plus 'overview'
      expect(page).not_to have_selector('[data-qa-selector="op-menu--item-action"]', text: I18n.t('timelines.admin_menu.colors'))
    end
  end

  context 'when logged in with a non-admin user with specific admin permissions' do
    let(:user) { create :user, global_permission: %i[manage_user create_backup] }

    it 'must display only the actions allowed by global permissions' do
      visit admin_index_path

      expect(page).to have_selector('[data-qa-selector="menu-block"]', text: I18n.t('label_user_plural'))
      expect(page).to have_selector('[data-qa-selector="menu-block"]', text: I18n.t('label_backup'))
      expect(page).to have_selector('[data-qa-selector="op-menu--item-action"]', text: I18n.t('label_user_plural'))
      expect(page).to have_selector('[data-qa-selector="op-menu--item-action"]', text: I18n.t('label_backup'))
    end
  end
end
