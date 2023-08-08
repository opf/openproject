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

RSpec.describe 'baseline query saving',
               :js,
               :with_cuprite,
               with_ee: %i[baseline_comparison],
               with_settings: { date_format: '%Y-%m-%d' } do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:baseline) { Components::WorkPackages::Baseline.new }
  let(:baseline_modal) { Components::WorkPackages::BaselineModal.new }
  let(:filters) { Components::WorkPackages::Filters.new }

  shared_let(:berlin_user) do
    create(:user,
           preferences: { time_zone: 'Europe/Berlin' },
           member_in_project: project,
           member_with_permissions: %i[view_work_packages save_queries manage_public_queries])
  end

  shared_let(:tokyo_user) do
    create(:user,
           preferences: { time_zone: 'Asia/Tokyo' },
           member_in_project: project,
           member_with_permissions: %i[view_work_packages save_queries manage_public_queries])
  end

  it 'shows a warning when an incompatible filter is used' do
    login_as berlin_user
    wp_table.visit!

    baseline_modal.expect_closed
    baseline.expect_no_legends
    baseline_modal.toggle_drop_modal
    baseline_modal.expect_open
    baseline_modal.expect_selected '-'

    baseline_modal.select_filter 'yesterday'
    baseline_modal.set_time '09:00'
    baseline_modal.expect_offset 'UTC+2'
    baseline_modal.apply

    loading_indicator_saveguard

    filters.open
    filters.add_filter_by('Watcher', 'is (OR)', 'me')

    loading_indicator_saveguard

    expect(page).to have_selector(
      '.op-toast.-warning',
      text: 'Baseline mode is on but some of your active filters are not included in the comparison.'
    )
    page.within('#filter_watcher') do
      expect(page).to have_selector('[data-qa-selector="query-filter-baseline-incompatible"]')
    end
  end

  it 'can configure and save baseline queries' do
    login_as berlin_user
    wp_table.visit!

    baseline_modal.expect_closed
    baseline.expect_no_legends
    baseline_modal.toggle_drop_modal
    baseline_modal.expect_open
    baseline_modal.expect_selected '-'

    baseline_modal.select_filter 'yesterday'
    baseline_modal.set_time '09:00'
    baseline_modal.expect_offset 'UTC+2'
    baseline_modal.apply

    loading_indicator_saveguard

    baseline_modal.toggle_drop_modal
    baseline_modal.expect_open
    baseline_modal.expect_selected 'yesterday'
    baseline_modal.toggle_drop_modal
    baseline_modal.expect_closed
    baseline.expect_legends
    baseline.expect_legend_text "Changes since yesterday (#{Date.yesterday.iso8601} 9:00 AM UTC+2)"
    expect(page).to have_selector(".op-baseline-legends--details-added", text: 'Now meets filter criteria (1)')
    expect(page).to have_selector(".op-baseline-legends--details-removed", text: 'No longer meets filter criteria (0)')
    expect(page).to have_selector(".op-baseline-legends--details-changed", text: 'Maintained with changes (0)')

    wp_table.save_as 'Baseline query'
    wp_table.expect_and_dismiss_toaster(message: 'Successful creation.')

    query = retry_block { Query.find_by! name: 'Baseline query' }
    expect(query.timestamps.map(&:to_s)).to eq ['oneDayAgo@09:00+02:00', 'PT0S']
    query.update! public: true

    login_as tokyo_user
    wp_table.visit_query query
    baseline.expect_legend_text "Changes since yesterday (#{Date.yesterday.iso8601} 9:00 AM UTC+2)"
    baseline.expect_legend_tooltip "In your local timezone: #{Date.yesterday.iso8601} 4:00 PM UTC+9"

    baseline_modal.expect_closed
    baseline_modal.toggle_drop_modal
    baseline_modal.expect_open
    baseline_modal.expect_selected 'yesterday'
    baseline_modal.expect_selected_time '09:00'
    baseline_modal.expect_offset 'UTC+2'
    baseline_modal.select_filter '-'

    baseline_modal.select_filter 'yesterday'
    baseline_modal.expect_offset 'UTC+9'
    baseline_modal.select_filter '-'

    baseline_modal.apply
    baseline.expect_no_legends

    loading_indicator_saveguard
    wp_table.save
    wp_table.expect_and_dismiss_toaster(message: 'Successful update.')

    query.reload
    expect(query.timestamps).to eq ['PT0S']

    baseline_modal.expect_closed
    baseline_modal.toggle_drop_modal
    baseline_modal.expect_open
    baseline_modal.select_filter 'a specific date'
    baseline_modal.expect_offset 'UTC+9'
    baseline_modal.set_time '06:00'
    baseline_modal.set_date '2023-05-20'
    baseline_modal.apply

    loading_indicator_saveguard

    wp_table.save
    wp_table.expect_and_dismiss_toaster(message: 'Successful update.')

    query.reload
    expect(query.timestamps.map(&:to_s)).to eq ['2023-05-20T06:00+09:00', 'PT0S']

    login_as berlin_user
    wp_table.visit_query query
    baseline.expect_legend_text "Changes since 2023-05-20 6:00 AM UTC+9"
    baseline.expect_legend_tooltip "In your local timezone: 2023-05-19 11:00 PM UTC+2"

    baseline_modal.expect_closed
    baseline_modal.toggle_drop_modal
    baseline_modal.expect_open
    baseline_modal.expect_selected 'a specific date'
    baseline_modal.expect_selected_time '06:00'
    baseline_modal.expect_offset 'UTC+9'
    baseline_modal.expect_time_help_text "In your local time: 2023-05-19 11:00 PM"
    baseline_modal.select_filter 'between two specific dates'

    baseline_modal.set_between_dates from: '2023-05-19',
                                     to: '2023-05-25',
                                     from_time: '08:00',
                                     to_time: '20:00'

    baseline_modal.apply

    loading_indicator_saveguard

    wp_table.save
    wp_table.expect_and_dismiss_toaster(message: 'Successful update.')

    query.reload
    expect(query.timestamps.map(&:to_s)).to eq ['2023-05-19T08:00+02:00', '2023-05-25T20:00+02:00']

    login_as tokyo_user
    wp_table.visit_query query
    baseline.expect_legend_text "Changes between 2023-05-19 8:00 AM UTC+2 and 2023-05-25 8:00 PM UTC+2"
    baseline.expect_legend_tooltip "In your local timezone: 2023-05-19 3:00 PM UTC+9 - 2023-05-26 3:00 AM UTC+9"

    baseline_modal.expect_closed
    baseline_modal.toggle_drop_modal
    baseline_modal.expect_open
    baseline_modal.expect_selected 'between two specific dates'
    baseline_modal.expect_between_dates from: '2023-05-19',
                                        to: '2023-05-25',
                                        from_time: '08:00',
                                        to_time: '20:00'

    baseline_modal.expect_offset 'UTC+2', count: 2
  end
end
