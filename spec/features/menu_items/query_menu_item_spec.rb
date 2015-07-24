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
require 'features/work_packages/shared_contexts'
require 'features/work_packages/work_packages_page'

feature 'Query menu items' do
  let(:user) { FactoryGirl.create :admin }
  let(:project) { FactoryGirl.create :project }
  let(:work_packages_page) { WorkPackagesPage.new(project) }

  def visit_index_page(query)
    work_packages_page.select_query(query)
  end

  before do
    allow(User).to receive(:current).and_return user
  end

  context 'with identical names' do
    let(:query_a) { FactoryGirl.create :public_query, name: 'some query.', project: project }
    let(:query_b) { FactoryGirl.create :public_query, name: query_a.name, project: project }

    let!(:menu_item_a) { FactoryGirl.create :query_menu_item, query: query_a }
    let!(:menu_item_b) { FactoryGirl.create :query_menu_item, query: query_b }

    it 'can be shown' do
      visit_index_page(query_a)

      expect(page).to have_selector('a', text: query_a.name, count: 2)
    end
  end

  context 'with dots in their name' do
    let(:query) { FactoryGirl.create :public_query, name: 'OP 3.0', project: project }

    def check(input_name)
      find(:css, "input[name=#{input_name}]").set true
    end

    it 'can be added', js: true do
      visit_index_page(query)

      click_on 'Settings'
      click_on 'Share ...'
      check 'show_in_menu'
      click_on 'Save'

      expect(page).to have_selector('.flash', text: 'Successful update')
      expect(page).to have_selector('a', text: query.name)
    end

    after do
      ensure_wp_table_loaded
    end
  end

  describe 'renaming a menu item' do
    let(:query_a) { FactoryGirl.create :query, name: 'bbbb', project: project, user: user }
    let(:query_b) { FactoryGirl.create :query, name: 'zzzz', project: project, user: user }

    let!(:menu_item_a) { FactoryGirl.create :query_menu_item, query: query_a }
    let!(:menu_item_b) { FactoryGirl.create :query_menu_item, query: query_b }
    let(:new_name) { 'aaaaa' }

    before do
      visit_index_page(query_b)

      click_on I18n.t('js.button_settings')
      click_on I18n.t('js.toolbar.settings.page_settings')
      fill_in I18n.t('js.modals.label_name'), with: new_name
      click_on I18n.t('js.modals.button_submit')
    end

    after do
      ensure_wp_table_loaded
    end

    it 'displaying a success message', js: true do
      expect(page).to have_selector('.flash', text: 'Successful update')
    end

    it 'is renaming and reordering the list', js: true do
      ng_wait
      # Renaming the query should also reorder the queries.  As it is renamed
      # from zzzz to aaaa, it should now be the first query menu item.
      expect(page).to have_selector('li:nth-child(3) a', text: new_name)
    end
  end
end
