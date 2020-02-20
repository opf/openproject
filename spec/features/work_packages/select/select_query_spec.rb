#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
require 'features/work_packages/work_packages_page'

describe 'Query selection', type: :feature do
  let(:project) { FactoryBot.create :project, identifier: 'test_project', public: false }
  let(:role) { FactoryBot.create :role, permissions: [:view_work_packages] }
  let(:current_user) do
    FactoryBot.create :user, member_in_project: project,
                             member_through_role: role
  end

  let(:default_status) { FactoryBot.create(:default_status) }
  let(:wp_page) { ::Pages::WorkPackagesTable.new project }
  let(:filters) { ::Components::WorkPackages::Filters.new }

  let(:query) do
    FactoryBot.build(:query, project: project, is_public: true).tap do |query|
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
      filters.open
    end

    it 'shows the default (status) filter', js: true do
      filters.expect_filter_count 1
      filters.expect_filter_by 'Status', 'open', nil
    end
  end

  context 'when a query is selected' do
    before do
      query

      work_packages_page.select_query query
    end

    it 'shows the saved filters', js: true do
      filters.open
      filters.expect_filter_by 'Assignee', 'is',  ['me']
      filters.expect_filter_by 'Progress (%)', '>=',  ['10'], 'percentageDone'
    end

    it 'shows filter count within toggle button', js: true do
      expect(find_button('Activate Filter')).to have_text /2$/
    end
  end

  context 'when the selected query is changed' do
    let(:query2) do
      FactoryBot.create(:query, project: project, is_public: true)
    end

    before do
      query
      query2

      work_packages_page.select_query query
    end

    it 'updates the page upon query switching', js: true do
      wp_page.expect_title query.name, editable: false

      find('.wp-query-menu--item-link', text: query2.name).click
    end
  end
end
