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

describe 'Query menu item', js: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create :project }
  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:filters) { ::Components::WorkPackages::Filters.new }
  let(:query_title) { ::Components::WorkPackages::QueryTitle.new }

  before do
    login_as(user)
  end

  context 'visiting the global work packages page' do
    let(:wp_table) { ::Pages::WorkPackagesTable.new }
    it 'should show the query menu (Regression #30082)' do
      wp_table.visit!
      expect(page).to have_selector('.wp-query-menu--container')
      expect(page).to have_selector('.wp-query-menu--item', wait: 20, minimum: 1)
    end
  end

  context 'filtering by version in project' do
    let(:version) { FactoryBot.create :version, project: project }
    let(:work_package_with_version) { FactoryBot.create :work_package, project: project, version: version }
    let(:work_package_without_version) { FactoryBot.create :work_package, project: project }

    before do
      work_package_with_version
      work_package_without_version

      wp_table.visit!
    end

    it 'allows to save query as name with sharing options (Regression #27915)' do
      # Publish query
      wp_table.click_setting_item 'Save as'

      fill_in 'save-query-name', with: 'Some query name'
      find('#show-in-menu').set true
      find('#show-public').set true

      find('.button', text: 'Save').click

      expect(page).to have_selector('.ui-menu-item', text: 'Some query name', wait: 20)

      last_query = Query.last
      expect(last_query.is_public).to be_truthy
    end

    it 'only saves a single query when saving through the title input (Regression #31095)' do
      filters.open
      filters.remove_filter('status')

      filters.expect_filter_count 0
      query_title.expect_changed

      query_title.input_field.click
      query_title.rename 'My special query!123'

      query_title.expect_title 'My special query!123'
      expect(page).to have_selector('.ui-menu-item', text: 'My special query!123', wait: 20, count: 1)
    end

    it 'allows filtering, saving, retrieving and altering the saved filter (Regression #25372)' do
      filters.open
      filters.add_filter_by('Version', 'is', version.name)

      wp_table.expect_work_package_listed work_package_with_version
      wp_table.ensure_work_package_not_listed! work_package_without_version

      wp_table.save_as('Some query name')

      filters.remove_filter 'version'
      filters.expect_filter_count 1

      wp_table.expect_work_package_listed work_package_with_version, work_package_without_version

      last_query = Query.last

      expect(URI.parse(page.current_url).query).to include("query_id=#{last_query.id}&query_props=")

      # Publish query
      wp_table.click_setting_item I18n.t('js.label_visibility_settings')
      find('#show-in-menu').set true
      find('.button', text: 'Save').click

      wp_table.visit!
      loading_indicator_saveguard

      filters.open
      filters.remove_filter 'status'
      filters.expect_filter_count 0

      wp_table.expect_work_package_listed work_package_with_version, work_package_without_version

      # Locate query
      query_item = page.find(".ui-menu-item", text: 'Some query name')
      query_item.click

      # Overrides the query_props
      retry_block do
        # Run in retry block because page.current_url is not synchronized
        raise 'query_props should not be in URL path' if page.current_url.include?('query_props')
      end

      wp_table.expect_work_package_listed work_package_with_version
      wp_table.ensure_work_package_not_listed! work_package_without_version

      filters.expect_filter_count 2
      filters.open
      filters.expect_filter_by('Version', 'is', version.name)

      # Removing the filter and returning to query restores it
      filters.remove_filter 'version'
      filters.expect_filter_count 1
      expect(page.current_url).to include('query_props')

      query_item = page.find(".ui-menu-item", text: 'Some query name')
      query_item.click

      retry_block do
        # Run in retry block because page.current_url is not synchronized
        raise 'query_props should not be in URL path' if page.current_url.include?('query_props')
      end

      filters.expect_filter_count 2
      filters.open
      filters.expect_filter_by('Version', 'is', version.name)
    end
  end
end
