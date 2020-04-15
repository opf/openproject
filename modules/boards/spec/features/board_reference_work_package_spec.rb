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
require_relative './support/board_index_page'
require_relative './support/board_page'

describe 'Board reference work package spec', type: :feature, js: true do
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:project) { FactoryBot.create(:project, enabled_module_names: %i[work_package_tracking board_view]) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let!(:work_package) { FactoryBot.create :work_package, version: version, subject: 'Foo', project: project }

  let(:board_index) { Pages::BoardIndex.new(project) }
  let(:filters) { ::Components::WorkPackages::Filters.new }

  let(:permissions) do
    %i[
      show_board_views
      manage_board_views
      add_work_packages
      view_work_packages
      edit_work_packages
      manage_public_queries
      assign_versions
    ]
  end
  let(:board_view) { FactoryBot.create :board_grid_with_query, project: project }

  let!(:priority) { FactoryBot.create :default_priority }
  let!(:status) { FactoryBot.create :default_status }
  let!(:version) { FactoryBot.create :version, name: 'Foo version', project: project }

  before do
    with_enterprise_token :board_view
    project
    login_as(user)
  end

  it 'allows referencing with filters (Regression #29966)' do
    board_view
    board_index.visit!

    # Create new board
    board_page = board_index.create_board action: nil
    board_page.rename_list 'Unnamed list', 'First'

    # Filter for Version
    filters.open
    filters.add_filter_by('Version', 'is', version.name)
    sleep 2

    # Reference an existing work package
    board_page.reference('First', work_package)
    sleep 2
    board_page.expect_card('First', work_package.subject)

    queries = board_page.board(reload: true).contained_queries
    first = queries.find_by(name: 'First')
    ids = first.ordered_work_packages.pluck(:work_package_id)
    expect(ids).to match_array [work_package.id]

    # Reload work package expect version to be applied by filter
    work_package.reload
    expect(work_package.version_id).to eq version.id
  end

  context 'with a subproject and work packages within it (Regression #31613)' do
    let!(:child_project) { FactoryBot.create(:project, parent: project) }
    let!(:work_package) { FactoryBot.create(:work_package, subject: 'WP SUB', project: child_project) }

    let(:user) do
      FactoryBot.create(:user,
                        member_in_projects: [project, child_project],
                        member_through_role: role)
    end

    it 'returns the work package when subproject filters is added' do
      board_view
      board_index.visit!

      # Create new board
      board_page = board_index.create_board action: nil
      board_page.rename_list 'Unnamed list', 'First'

      # Reference an existing work package
      board_page.expect_not_referencable('First', work_package)
      sleep 2
      board_page.expect_card('First', work_package.subject, present: false)

      # Add subproject filter
      filters.open
      filters.add_filter_by('Subproject', 'all', nil, 'subprojectId')
      sleep 2

      # Reference an existing work package
      board_page.reference('First', work_package)
      sleep 2
      board_page.expect_card('First', work_package.subject)

      queries = board_page.board(reload: true).contained_queries
      first = queries.find_by(name: 'First')
      ids = first.ordered_work_packages.pluck(:work_package_id)
      expect(ids).to match_array [work_package.id]

      work_package.reload
      expect(work_package.project).to eq(child_project)
    end
  end
end
