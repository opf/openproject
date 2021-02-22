#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Work package filtering by id', js: true do
  let(:project) { FactoryBot.create :project }
  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:filters) { ::Components::WorkPackages::Filters.new }
  let(:role) { FactoryBot.create(:role, permissions: %i[view_work_packages save_queries]) }

  let!(:work_package) do
    FactoryBot.create :work_package,
                      project: project
  end
  let!(:other_work_package) do
    FactoryBot.create :work_package,
                      project: project

  end

  current_user do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_through_role: role
  end

  it 'shows the work package matching the id filter' do
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package, other_work_package)

    filters.open
    filters.add_filter_by('ID', 'is', [work_package.subject])

    wp_table.ensure_work_package_not_listed!(other_work_package)
    wp_table.expect_work_package_listed(work_package)

    wp_table.save_as('Id query')

    wp_table.expect_and_dismiss_notification(message: 'Successful creation.')

    # Revisit query
    wp_table.visit_query Query.last
    wp_table.ensure_work_package_not_listed!(other_work_package)
    wp_table.expect_work_package_listed(work_package)

    filters.open
    filters.expect_filter_by('ID', 'is', [work_package.subject])
    filters.remove_filter 'id'
    filters.add_filter_by('ID', 'is not', [work_package.subject, other_work_package.subject])

    wp_table.expect_no_work_package_listed
  end
end
