#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe 'baseline query saving', js: true do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:baseline) { Components::WorkPackages::Baseline.new }
  let(:baseline_modal) { Components::WorkPackages::BaselineModal.new }

  current_user do
    create(:user,
           member_in_project: project,
           member_with_permissions: %i[view_work_packages save_queries])
  end

  it 'can configure and save baseline queries', with_flag: { show_changes: true } do
    wp_table.visit!

    baseline_modal.expect_closed
    baseline_modal.toggle_drop_modal
    baseline_modal.expect_open
    baseline_modal.expect_selected '-'

    baseline_modal.select_filter 'yesterday'
    baseline_modal.apply

    loading_indicator_saveguard

    baseline_modal.toggle_drop_modal
    baseline_modal.expect_open
    baseline_modal.expect_selected 'yesterday'
    baseline_modal.toggle_drop_modal
    baseline_modal.expect_closed

    wp_table.save_as 'Baseline query'
    wp_table.expect_and_dismiss_toaster(message: 'Successful creation.')

    query = retry_block { Query.find_by! name: 'Baseline query' }
    expect(query.timestamps).to eq ['oneDayAgo@00:00', 'PT0S']

    wp_table.visit_query query

    baseline_modal.expect_closed
    baseline_modal.toggle_drop_modal
    baseline_modal.expect_open
    baseline_modal.expect_selected 'yesterday'
    baseline_modal.select_filter '-'
    baseline_modal.apply

    loading_indicator_saveguard
    wp_table.save
    wp_table.expect_and_dismiss_toaster(message: 'Successful update.')

    query.reload
    expect(query.timestamps).to eq ['PT0S']
  end
end
