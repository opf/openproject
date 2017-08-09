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

describe 'Query menu item', js: true do
  let(:user) { FactoryGirl.create :admin }
  let(:project) { FactoryGirl.create :project }
  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:filters) { ::Components::WorkPackages::Filters.new }

  before do
    login_as(user)
  end

  context 'filtering by version in project' do
    let(:version) { FactoryGirl.create :version, project: project }
    let(:work_package_with_version) { FactoryGirl.create :work_package, project: project, fixed_version: version }
    let(:work_package_without_version) { FactoryGirl.create :work_package, project: project }

    before do
      work_package_with_version
      work_package_without_version

      wp_table.visit!
    end

    it 'allows filtering, saving, retrieving and altering the saved filter (Regression #25372)' do
      filters.open
      filters.add_filter_by('Version', 'is', version.name)

      expect(wp_table).to have_work_packages_listed [work_package_with_version]
      expect(wp_table).not_to have_work_packages_listed [work_package_without_version]

      wp_table.save_as('Some query name')

      filters.remove_filter 'version'
      filters.expect_filter_count 1

      expect(wp_table).to have_work_packages_listed [work_package_with_version, work_package_without_version]

      last_query = Query.last

      expect(URI.parse(page.current_url).query).to include("query_id=#{last_query.id}&query_props=")

      # Publish query
      wp_table.click_setting_item 'Publish'
      find('#show-in-menu').set true
      find('.button', text: 'Save').click

      wp_table.visit!
      loading_indicator_saveguard

      filters.open
      filters.remove_filter 'status'
      filters.expect_filter_count 0

      expect(wp_table).to have_work_packages_listed [work_package_with_version, work_package_without_version]

      # Locate query
      query_item = page.find(".query-menu-item[object-id='#{last_query.id}']")
      query_item.click

      # Overrides the query_props
      expect(page.current_url).not_to include('query_props')

      expect(wp_table).to have_work_packages_listed [work_package_with_version]
      expect(wp_table).not_to have_work_packages_listed [work_package_without_version]

      filters.expect_filter_count 2
      filters.expect_filter_by('Version', 'is', version.name)

      # Removing the filter and returning to query restores it
      filters.remove_filter 'version'
      filters.expect_filter_count 1
      expect(page.current_url).to include('query_props')

      query_item = page.find(".query-menu-item[object-id='#{last_query.id}']")
      query_item.click

      expect(page.current_url).not_to include('query_props')
      filters.expect_filter_count 2
      filters.expect_filter_by('Version', 'is', version.name)
    end
  end
end
