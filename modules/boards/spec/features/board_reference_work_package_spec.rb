#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
  let!(:work_package) { FactoryBot.create :work_package, subject: 'Foo', project: project }

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
    subjects = WorkPackage.where(id: first.ordered_work_packages).pluck(:subject)
    expect(subjects).to match_array [work_package.subject]

    # Reload work package expect version to be applied by filter
    work_package.reload
    expect(work_package.fixed_version_id).to eq version.id
  end
end
