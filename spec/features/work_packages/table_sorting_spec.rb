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

describe 'Select work package row', type: :feature, js: true do
  let(:user) { FactoryGirl.create(:admin) }
  let(:project) { FactoryGirl.create(:project) }
  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  describe 'sorting by version' do
    let(:work_package_1) do
      FactoryGirl.create(:work_package, project: project)
    end
    let(:work_package_2) do
      FactoryGirl.create(:work_package, project: project)
    end

    let(:version_1) do
      FactoryGirl.create(:version, project: project,
                                   name: 'aaa_version')
    end
    let(:version_2) do
      FactoryGirl.create(:version, project: project,
                                   name: 'zzz_version')
    end
    let(:columns) { ::Components::WorkPackages::Columns.new }

    before do
      login_as(user)

      work_package_1
      work_package_2

      work_packages_page.visit_index
    end

    include_context 'ui-select helpers'
    include_context 'work package table helpers'

    context 'sorting by version' do
      before do
        work_package_1.update_attribute(:fixed_version_id, version_2.id)
        work_package_2.update_attribute(:fixed_version_id, version_1.id)
      end

      it 'sorts by version although version is not selected as a column' do
        columns.remove 'Version'

        sort_wp_table_by('Version')

        expect_work_packages_to_be_in_order([work_package_1, work_package_2])
      end
    end
  end

  describe 'sorting modal' do
    let(:sort_by) { ::Components::WorkPackages::SortBy.new }

    before do
      login_as user
      wp_table.visit!
    end

    it 'provides the default sortation and allows using the value at another level (Regression WP#26792)' do
      # Expect current criteria
      sort_by.expect_criteria(['Parent', 'asc'])

      # Expect we can change the criteria and reuse that value
      sort_by.open_modal
      sort_by.update_nth_criteria(0, 'ID', descending: true)
      sort_by.update_nth_criteria(1, 'Parent')

      sort_by.apply_changes
      sort_by.expect_criteria(['ID', 'desc'], ['Parent', 'asc'])
    end
  end

  describe 'parent sorting' do
    let(:sort_by) { ::Components::WorkPackages::SortBy.new }

    let(:parent) do
      FactoryGirl.create :work_package,
                         project: project
    end
    let(:child1) do
      FactoryGirl.create :work_package,
                         project: project,
                         parent: parent
    end
    let(:child2) do
      FactoryGirl.create :work_package,
                         project: project,
                         parent: parent
    end
    let(:grand_child1) do
      FactoryGirl.create :work_package,
                         project: project,
                         parent: child1
    end
    let(:grand_child2) do
      FactoryGirl.create :work_package,
                         project: project,
                         parent: child2
    end
    let(:grand_child3) do
      FactoryGirl.create :work_package,
                         project: project,
                         parent: child1
    end

    before do
      allow(Setting).to receive(:per_page_options).and_return '4'

      parent
      child1
      grand_child1
      child2
      grand_child2
      grand_child3

      login_as user
      wp_table.visit!
    end

    it 'default sortation (parent) orders depth first' do
      wp_table.expect_work_package_listed parent, child1, grand_child1, grand_child3
      wp_table.expect_work_package_order parent.id, child1.id, grand_child1.id, grand_child3.id
    end
  end
end
