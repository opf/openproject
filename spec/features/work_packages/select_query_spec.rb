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
require 'features/work_packages/work_packages_page'

describe 'Query selection', type: :feature do
  let(:project) { FactoryGirl.create :project, identifier: 'test_project', is_public: false }
  let(:role) { FactoryGirl.create :role, permissions: [:view_work_packages] }
  let(:current_user) do
    FactoryGirl.create :user, member_in_project: project,
                              member_through_role: role
  end

  let(:filter_1_name) { 'assignee' }
  let(:filter_2_name) { 'percentageDone' }
  let(:i18n_filter_1_name) { WorkPackage.human_attribute_name(:assigned_to) }
  let(:i18n_filter_2_name) { WorkPackage.human_attribute_name(:done_ratio) }
  let(:default_status) { FactoryGirl.create(:default_status) }

  let(:query) do
    FactoryGirl.build(:query, project: project, is_public: true).tap do |query|
      query.filters.clear
      query.add_filter('assigned_to_id', '=', ['me'])
      query.add_filter('done_ratio', '>=', [10])
      query.save!
    end
  end

  let(:work_packages_page) { WorkPackagesPage.new(project) }

  before do
    default_status

    login_as(current_user)
  end

  context 'default view, without a query selected' do
    before do
      work_packages_page.visit_index
      # ensure the page is loaded before expecting anything
      find('.advanced-filters--filters select option', text: /\AAssignee\Z/,
                                                       visible: false)
    end

    it 'shows the default (status) filter', js: true do
      work_packages_page.click_toolbar_button 'Activate Filter'
      expect(work_packages_page.find_filter('status')).to have_content('Status')
      expect(work_packages_page.find_filter('status'))
        .to have_select('operators-status', selected: 'open')
    end

    it 'shows filter count within toggle button', js: true do
      expect(find_button('Activate Filter')).to have_text /1$/
    end
  end

  context 'when a query is selected' do
    before do
      query

      work_packages_page.select_query query
    end

    it 'shows the saved filters', js: true do
      work_packages_page.click_toolbar_button 'Activate Filter'
      expect(work_packages_page.find_filter(filter_1_name)).to have_content(i18n_filter_1_name)
      expect(work_packages_page.find_filter(filter_2_name)).to have_content(i18n_filter_2_name)
    end

    it 'shows filter count within toggle button', js: true do
      expect(find_button('Activate Filter')).to have_text /2$/
    end
  end

  context 'when the selected query is changed' do
    let(:query2) do
      FactoryGirl.create(:query, project: project, is_public: true)
    end

    before do
      query
      query2

      work_packages_page.select_query query
    end

    it 'updates the page upon query switching', js: true do
      work_packages_page.expect_query(query)
      work_packages_page.select_query_from_dropdown(query2)
      work_packages_page.expect_query(query2)
    end
  end
end
