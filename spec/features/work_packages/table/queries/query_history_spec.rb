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

describe 'Going back and forth through the browser history', type: :feature, js: true do
  let(:user) do
    FactoryBot.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  end
  let(:project) { FactoryBot.create(:project) }
  let(:type) { project.types.first }
  let(:role) do
    FactoryBot.create(:role,
                       permissions: [:view_work_packages,
                                     :save_queries])
  end

  let(:work_package_1) do
    FactoryBot.create(:work_package,
                       project: project,
                       type: type)
  end
  let(:work_package_2) do
    FactoryBot.create(:work_package,
                       project: project,
                       type: type,
                       assigned_to: user)
  end
  let(:version) do
    FactoryBot.create(:version,
                       project: project)
  end
  let(:work_package_3) do
    FactoryBot.create(:work_package,
                       project: project,
                       type: type,
                       version: version)
  end
  let(:assignee_query) do
    query = FactoryBot.create(:query,
                               name: 'Assignee Query',
                               project: project,
                               user: user)

    query.add_filter('assigned_to_id', '=', [user.id])
    query.save!

    query
  end
  let(:version_query) do
    query = FactoryBot.create(:query,
                               name: 'Version Query',
                               project: project,
                               user: user)

    query.add_filter('version_id', '=', [version.id])
    query.save!

    query
  end
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:filters) { ::Components::WorkPackages::Filters.new }

  before do
    login_as(user)

    work_package_1
    work_package_2
    work_package_3

    assignee_query
    version_query
  end

  it 'updates the filters and query results on history back and forth', retry: 1 do
    wp_table.visit!
    wp_table.expect_title('All open', editable: true)

    wp_table.visit_query(assignee_query)
    wp_table.expect_title(assignee_query.name)
    wp_table.expect_work_package_listed work_package_2

    wp_table.visit_query(version_query)
    wp_table.expect_title(version_query.name)
    wp_table.expect_work_package_listed work_package_3

    filters.open
    filters.add_filter_by('Assignee', 'is', user.name)
    filters.expect_filter_count 3
    wp_table.expect_no_work_package_listed

    page.execute_script('window.history.back()')

    wp_table.expect_title(version_query.name)
    wp_table.expect_work_package_listed work_package_3
    filters.expect_filter_count 2
    filters.expect_filter_by('Status', 'open', nil)
    filters.expect_filter_by('Version', 'is', version.name)

    page.execute_script('window.history.back()')

    wp_table.expect_title(assignee_query.name)
    wp_table.expect_work_package_listed work_package_2
    filters.open
    filters.expect_filter_by('Status', 'open', nil)
    filters.expect_filter_by('Assignee', 'is', user.name)

    page.execute_script('window.history.back()')

    wp_table.expect_title('All open', editable: true)
    wp_table.expect_work_package_listed work_package_1
    wp_table.expect_work_package_listed work_package_2
    wp_table.expect_work_package_listed work_package_3
    filters.open
    filters.expect_filter_by('Status', 'open', nil)

    page.execute_script('window.history.forward()')

    wp_table.expect_title(assignee_query.name)
    wp_table.expect_work_package_listed work_package_2
    filters.open
    filters.expect_filter_by('Status', 'open', nil)
    filters.expect_filter_by('Assignee', 'is', user.name)

    page.execute_script('window.history.forward()')

    wp_table.expect_title(version_query.name)
    wp_table.expect_work_package_listed work_package_3
    filters.open
    filters.expect_filter_by('Status', 'open', nil)
    filters.expect_filter_by('Version', 'is', version.name)

    page.execute_script('window.history.forward()')

    wp_table.expect_title(version_query.name)
    wp_table.expect_no_work_package_listed
    filters.open
    filters.expect_filter_by('Status', 'open', nil)
    filters.expect_filter_by('Version', 'is', version.name)
    filters.expect_filter_by('Assignee', 'is', user.name)
  end
end
