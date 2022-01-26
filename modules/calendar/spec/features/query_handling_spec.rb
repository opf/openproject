#-- encoding: UTF-8

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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'
require_relative '../support/pages/calendar'
require_relative '../../../../spec/features/views/shared_examples'

describe 'Calendar query handling', type: :feature, js: true do
  shared_let(:type_task) { create(:type_task) }
  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:project) do
    create(:project,
                      enabled_module_names: %w[work_package_tracking calendar_view],
                      types: [type_task, type_bug])
  end

  shared_let(:user) do
    create :user,
                      member_in_project: project,
                      member_with_permissions: %w[
                        view_work_packages
                        edit_work_packages
                        save_queries
                        save_public_queries
                        view_calendar
                      ]
  end

  shared_let(:task) do
    create :work_package,
                      project: project,
                      type: type_task,
                      assigned_to: user,
                      start_date: Time.zone.today - 1.day,
                      due_date: Time.zone.today + 1.day,
                      subject: 'A task for the user'
  end
  shared_let(:bug) do
    create :work_package,
                      project: project,
                      type: type_bug,
                      assigned_to: user,
                      start_date: Time.zone.today - 1.day,
                      due_date: Time.zone.today + 1.day,
                      subject: 'A bug for the user'
  end

  shared_let(:saved_query) do
    create(:query_with_view_work_packages_calendar,
                      project: project,
                      public: true)
  end

  let(:calendar_page) { ::Pages::Calendar.new project }
  let(:work_package_page) { ::Pages::WorkPackagesTable.new project }
  let(:query_title) { ::Components::WorkPackages::QueryTitle.new }
  let(:query_menu) { ::Components::WorkPackages::QueryMenu.new }
  let(:filters) { calendar_page.filters }

  current_user { user }

  before do
    login_as user
    calendar_page.visit!

    loading_indicator_saveguard

    calendar_page.expect_event task
    calendar_page.expect_event bug
  end

  it 'allows saving the calendar' do
    filters.expect_filter_count("1")
    filters.open

    filters.add_filter_by('Type', 'is', [type_bug.name])

    filters.expect_filter_count("2")

    calendar_page.expect_event bug
    calendar_page.expect_event task, present: false

    query_title.expect_changed
    query_title.press_save_button

    calendar_page.expect_and_dismiss_toaster(message: I18n.t('js.notice_successful_create'))
  end

  it 'shows only calendar queries' do
    # Go to calendar where a query is already shown
    query_menu.expect_menu_entry saved_query.name

    # Change filter
    filters.open
    filters.add_filter_by('Type', 'is', [type_bug.name])
    filters.expect_filter_count("2")

    # Save current filters
    query_title.expect_changed
    query_title.rename 'I am your Query'
    calendar_page.expect_and_dismiss_toaster(message: I18n.t('js.notice_successful_create'))

    # The saved query appears in the side menu...
    query_menu.expect_menu_entry 'I am your Query'
    query_menu.expect_menu_entry saved_query.name

    # .. but not in the work packages module
    work_package_page.visit!
    query_menu.expect_menu_entry_not_visible 'I am your Query'
  end

  it_behaves_like 'module specific query view management' do
    let(:module_page) { calendar_page }
    let(:default_name) { 'Unnamed calendar' }
  end
end
