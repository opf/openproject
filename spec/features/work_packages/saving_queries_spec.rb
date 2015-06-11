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
require 'features/work_packages/work_packages_page'

describe 'Query Saving', type: :feature, js: true do
  let(:project) { FactoryGirl.create :project, identifier: 'test_project', is_public: false }
  let(:role) { FactoryGirl.create :role, permissions: [:view_work_packages] }
  let(:current_user) do
    FactoryGirl.create :user, member_in_project: project,
                              member_through_role: role,
                              admin: true
  end

  let(:filter_name) { 'done_ratio' }
  let!(:query) do
    query = FactoryGirl.build(:query, project: project, is_public: true)
    query.filters = [Queries::WorkPackages::Filter.new(filter_name, operator: '>=', values: [10])]
    query.save!
    query
  end
  let(:query_item) do
    FactoryGirl.create(:query_menu_item,
                       query: query,
                       name:  'Query Item',
                       title: 'Query Item')
  end

  let(:work_packages_page) { WorkPackagesPage.new(project) }

  before do
    query.query_menu_item = query_item
    allow(User).to receive(:current).and_return current_user
  end

  context 'when a query is loaded' do
    before do
      work_packages_page.select_query query
      # ensure the page is loaded before expecting anything
      find('.advanced-filters--filters select option', text: /\AAssignee\Z/,
                                                       visible: false)
    end

    xit 'should select its menu item' do
      expect(page).to have_css '#main-menu .query.selected'
      selected = find('#main-menu .query.selected')
      expect(selected).to have_text(query_item.name)
    end

    context 'after saving under a new name' do
      before do
        work_packages_page.click_toolbar_button 'Settings'
        find('#settingsDropdown').find_link('Save as ...').click
        fill_in 'query_name', with: 'newQueryName'
        find_button('Save').click
        # ensure the page is loaded before expecting anything
        find('.advanced-filters--filters select option', text: /\AAssignee\Z/,
                                                         visible: false)
      end

      xit 'should select the new menu item' do
        expect(page).to have_css '#main-menu .query-menu-item.selected'
        selected = find('#main-menu .query-menu-item.selected')
        expect(selected).to have_text('newQueryName')
      end
    end
  end
end
