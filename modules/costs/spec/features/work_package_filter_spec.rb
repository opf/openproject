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

describe 'Filter by budget', js: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create :project }

  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:filters) { ::Components::WorkPackages::Filters.new }

  let(:member) do
    FactoryBot.create(:member,
                       user: user,
                       project: project,
                       roles: [FactoryBot.create(:role)])
  end
  let(:status) do
    FactoryBot.create(:status)
  end

  let(:budget) do
    FactoryBot.create(:cost_object, project: project)
  end

  let(:work_package_with_budget) do
    FactoryBot.create(:work_package,
                       project: project,
                       cost_object: budget)
  end

  let(:work_package_without_budget) do
    FactoryBot.create(:work_package,
                       project: project)
  end

  before do
    login_as(user)
    member
    budget
    work_package_with_budget
    work_package_without_budget

    wp_table.visit!
  end

  it 'allows filtering for budgets' do
    wp_table.expect_work_package_listed work_package_with_budget, work_package_without_budget

    filters.expect_filter_count 1
    filters.open
    filters.add_filter_by('Budget', 'is', budget.name, 'costObject')

    wp_table.expect_work_package_listed work_package_with_budget
    wp_table.ensure_work_package_not_listed! work_package_without_budget

    wp_table.save_as('Some query name')

    wp_table.expect_and_dismiss_notification message: 'Successful creation.'

    filters.remove_filter 'costObject'

    wp_table.expect_work_package_listed work_package_with_budget, work_package_without_budget

    last_query = Query.last

    wp_table.visit_query(last_query)

    wp_table.expect_work_package_listed work_package_with_budget
    wp_table.ensure_work_package_not_listed! work_package_without_budget

    filters.open

    filters.expect_filter_by('Budget', 'is', budget.name, 'costObject')
  end
end
