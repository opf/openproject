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

feature 'Admin menu items' do
  let(:user) { FactoryGirl.create :admin }

  before do
    allow(User).to receive(:current).and_return user
  end

  after do
    OpenProject::Configuration['hidden_menu_items'] = []
  end

  describe 'displaying all the menu items' do
    it 'hides the specified admin menu items' do
      visit admin_path

      expect(page).to have_selector('a', text: I18n.t('label_user_plural'))
      expect(page).to have_selector('a', text: I18n.t('label_project_plural'))
      expect(page).to have_selector('a', text: I18n.t('label_role_plural'))
      expect(page).to have_selector("a[title=#{I18n.t('label_type_plural')}]")
    end
  end

  describe 'hiding menu items' do
    before do
      OpenProject::Configuration['hidden_menu_items'] = { 'admin_menu' => ['roles', 'types'] }
    end

    it 'hides the specified admin menu items' do
      visit admin_path

      expect(page).to have_selector('a', text: I18n.t('label_user_plural'))
      expect(page).to have_selector('a', text: I18n.t('label_project_plural'))

      expect(page).not_to have_selector('a', text: I18n.t('label_role_plural'))
      expect(page).not_to have_selector("a[title=#{I18n.t('label_type_plural')}]")
    end
  end
end
