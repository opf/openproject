#-- encoding: UTF-8

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

describe 'Work package calendars', type: :feature, js: true do
  let(:project) { FactoryBot.create(:project) }
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i[view_work_packages view_calendar])
  end
  let!(:current_work_package) do
    FactoryBot.create(:work_package,
                      subject: 'Current work package',
                      project: project,
                      start_date: Date.today,
                      due_date: Date.today)
  end
  let!(:another_current_work_package) do
    FactoryBot.create(:work_package,
                      subject: 'Another current work package',
                      project: project,
                      start_date: Date.today - 3.days,
                      due_date: Date.today + 3.days)
  end
  let(:filters) { ::Components::WorkPackages::Filters.new }

  before do
    login_as(user)
  end

  it 'navigates to today, allows filtering, switching the view and retrains the state' do
    visit project_path(project)

    within '#main-menu' do
      click_link 'Calendar'
    end

    # should open the calendar with the current month displayed
    expect(page)
      .to have_selector '.fc-event-container', text: current_work_package.subject
    expect(page)
      .to have_selector '.fc-event-container', text: another_current_work_package.subject

    # The filter for the time frame added implicitly should not be visible
    filters.expect_filter_count 1

    filters.open
    filters.add_filter_by 'Subject', 'contains', 'Another'

    # non matching work packages are no longer displayed
    expect(page)
      .to have_no_selector '.fc-event-container', text: current_work_package.subject
    expect(page)
      .to have_selector '.fc-event-container', text: another_current_work_package.subject

    # The filter for the time frame added implicitly should not be visible
    filters.expect_filter_count 2
  end
end
