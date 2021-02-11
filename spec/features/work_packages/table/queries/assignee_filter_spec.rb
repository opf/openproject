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

describe 'Work package filtering by assignee', js: true do
  let(:project) { FactoryBot.create :project }
  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:filters) { ::Components::WorkPackages::Filters.new }
  let(:role) { FactoryBot.create(:role, permissions: %i[view_work_packages save_queries]) }
  let(:other_user) do
    FactoryBot.create :user,
                      firstname: 'Other',
                      lastname: 'User',
                      member_in_project: project,
                      member_through_role: role
  end
  let(:placeholder_user) do
    FactoryBot.create :placeholder_user,
                      member_in_project: project,
                      member_through_role: role
  end

  let!(:work_package_user_assignee) do
    FactoryBot.create :work_package,
                      project: project,
                      assigned_to: other_user
  end
  let!(:work_package_placeholder_user_assignee) do
    FactoryBot.create :work_package,
                      project: project,
                      assigned_to: placeholder_user
  end

  current_user do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_through_role: role
  end

  it 'shows the work package matching the assigned to filter' do
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package_user_assignee, work_package_placeholder_user_assignee)

    filters.open
    filters.add_filter_by('Assignee', 'is', [other_user.name])

    wp_table.ensure_work_package_not_listed!(work_package_placeholder_user_assignee)
    wp_table.expect_work_package_listed(work_package_user_assignee)

    wp_table.save_as('Subject query')

    wp_table.expect_and_dismiss_notification(message: 'Successful creation.')

    # Revisit query
    wp_table.visit_query Query.last
    wp_table.ensure_work_package_not_listed!(work_package_placeholder_user_assignee)
    wp_table.expect_work_package_listed(work_package_user_assignee)

    filters.open
    filters.expect_filter_by('Assignee', 'is', [other_user.name])
    filters.remove_filter 'assignee'
    filters.add_filter_by('Assignee', 'is', [placeholder_user.name])

    wp_table.ensure_work_package_not_listed!(work_package_user_assignee)
    wp_table.expect_work_package_listed(work_package_placeholder_user_assignee)
  end
end
