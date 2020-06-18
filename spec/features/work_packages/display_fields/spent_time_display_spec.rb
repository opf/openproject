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

describe 'Logging time within the work package view', type: :feature, js: true do
  let(:project) { FactoryBot.create :project }
  let(:admin) { FactoryBot.create :admin }
  let(:user_without_permissions) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i[view_time_entries view_work_packages edit_work_packages])
  end

  let!(:activity) { FactoryBot.create :time_entry_activity, project: project }
  let(:spent_time_field) { ::SpentTimeEditField.new(page, 'spentTime') }

  let(:work_package) { FactoryBot.create :work_package, project: project }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }

  let(:time_logging_modal) { ::Components::TimeLoggingModal.new }

  def log_time_via_modal
    time_logging_modal.is_visible true

    # the fields are visible
    time_logging_modal.has_field_with_value 'spent_on', Date.today.strftime("%Y-%m-%d")
    time_logging_modal.shows_field 'work_package', false

    time_logging_modal.update_field 'activity', activity.name

    # a click on save creates a time entry
    time_logging_modal.perform_action 'Create'
    wp_page.expect_and_dismiss_notification message: 'Successful creation.'
  end

  context 'as an admin' do
    before do
      login_as(admin)
      wp_page.visit!
      loading_indicator_saveguard
      spent_time_field.time_log_icon_visible true
    end

    it 'shows a logging button within the display field and can log time via a modal' do
      # click on button opens modal
      spent_time_field.open_time_log_modal

      log_time_via_modal

      # the value is updated automatically
      spent_time_field.expect_display_value '1 h'
    end

    it 'the context menu entry to log time leads to the modal' do
      # click on context menu opens the modal
      find('#action-show-more-dropdown-menu .button').click
      find('.menu-item', text: 'Log time').click

      log_time_via_modal

      # the value is updated automatically
      spent_time_field.expect_display_value '1 h'
    end
  end

  context 'as a user who cannot log time' do
    before do
      login_as(user_without_permissions)
      wp_page.visit!
      loading_indicator_saveguard
    end

    it 'shows no logging button within the display field' do
      spent_time_field.time_log_icon_visible false
      spent_time_field.expect_display_value '-'
    end
  end

  context 'within the table' do
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }
    let(:second_work_package) { FactoryBot.create :work_package, project: project }
    let(:query) { FactoryBot.create :public_query, project: project, column_names: ['subject', 'spent_hours'] }

    before do
      work_package
      second_work_package
      login_as(admin)

      wp_table.visit_query query
      loading_indicator_saveguard
    end

    it 'shows no logging button within the display field' do
      wp_table.expect_work_package_listed work_package, second_work_package

      find('tr:nth-of-type(1) .wp-table--cell-td.spentTime .icon-time').click

      log_time_via_modal

      expect(page).to have_selector('tr:nth-of-type(1) .wp-table--cell-td.spentTime', text: '1 h')
      expect(page).to have_selector('tr:nth-of-type(2) .wp-table--cell-td.spentTime', text: '-')
    end
  end
end
