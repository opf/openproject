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

require_relative '../../support/pages/my/page'

describe 'My page time entries current user widget spec', type: :feature, js: true, with_mail: false do
  let!(:type) { FactoryBot.create :type }
  let!(:project) { FactoryBot.create :project, types: [type] }
  let!(:activity) { FactoryBot.create :time_entry_activity }
  let!(:other_activity) { FactoryBot.create :time_entry_activity }
  let!(:work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type,
                      author: user
  end
  let!(:other_work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type,
                      author: user
  end
  let!(:visible_time_entry) do
    FactoryBot.create :time_entry,
                      work_package: work_package,
                      project: project,
                      activity: activity,
                      user: user,
                      spent_on: Date.today.beginning_of_week(:sunday) + 1.day,
                      hours: 3,
                      comments: 'My comment'
  end
  let!(:other_visible_time_entry) do
    FactoryBot.create :time_entry,
                      work_package: work_package,
                      project: project,
                      activity: activity,
                      user: user,
                      spent_on: Date.today.beginning_of_week(:sunday) + 4.days,
                      hours: 2,
                      comments: 'My other comment'
  end
  let!(:last_week_visible_time_entry) do
    FactoryBot.create :time_entry,
                      work_package: work_package,
                      project: project,
                      activity: activity,
                      user: user,
                      spent_on: Date.today - (Date.today.wday + 3).days,
                      hours: 8,
                      comments: 'My last week comment'
  end
  let!(:invisible_time_entry) do
    FactoryBot.create :time_entry,
                      work_package: work_package,
                      project: project,
                      activity: activity,
                      user: other_user,
                      hours: 4
  end
  let!(:custom_field) do
    FactoryBot.create :time_entry_custom_field, field_format: 'string'
  end
  let(:other_user) do
    FactoryBot.create(:user)
  end
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i[view_time_entries edit_time_entries view_work_packages log_time])
  end
  let(:my_page) do
    Pages::My::Page.new
  end
  let(:comments_field) { ::EditField.new(page, 'comment') }
  let(:activity_field) { ::EditField.new(page, 'activity') }
  let(:hours_field) { ::EditField.new(page, 'hours') }
  let(:spent_on_field) { ::EditField.new(page, 'spentOn') }
  let(:wp_field) { ::EditField.new(page, 'workPackage') }
  let(:cf_field) { ::EditField.new(page, "customField#{custom_field.id}") }

  before do
    login_as user

    my_page.visit!
  end

  it 'adds the widget which then displays time entries and allows manipulating them' do
    # within top-right area, add an additional widget
    my_page.add_widget(1, 1, :within, 'My spent time')

    entries_area = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)')

    my_page.expect_and_dismiss_notification message: I18n.t(:notice_successful_update)

    entries_area.expect_to_span(1, 1, 2, 2)

    expect(page)
      .to have_content "Total: 5.00"

    expect(page)
      .to have_content visible_time_entry.spent_on.strftime('%-m/%-d')
    expect(page)
      .to have_selector('.fc-event .fc-title', text: "#{project.name} - ##{work_package.id}: #{work_package.subject}")

    expect(page)
      .to have_content(other_visible_time_entry.spent_on.strftime('%-m/%-d'))
    expect(page)
      .to have_selector('.fc-event .fc-title', text: "#{project.name} - ##{work_package.id}: #{work_package.subject}")

    # go to last week
    within entries_area.area do
      find('.fc-toolbar .fc-prev-button').click
    end

    expect(page)
      .to have_content "Total: 8.00"

    expect(page)
      .to have_content(last_week_visible_time_entry.spent_on.strftime('%-m/%-d'))
    expect(page)
      .to have_selector('.fc-event .fc-title', text: "#{project.name} - ##{work_package.id}: #{work_package.subject}")

    # go to today again
    within entries_area.area do
      find('.fc-toolbar .fc-today-button').click
    end

    expect(page)
      .to have_content "Total: 5.00"

    within entries_area.area do
      find(".fc-content-skeleton td:nth-of-type(3) .fc-event-container .te-calendar--time-entry").hover
    end

    expect(page)
      .to have_selector('.ui-tooltip', text: "Project: #{project.name}")

    # Adding a time entry

    # The add time entry event is invisible
    within entries_area.area do
      find(".fc-content-skeleton td:nth-of-type(5) .te-calendar--add-entry", visible: false).click
    end

    expect(page)
      .to have_content(I18n.t('js.time_entry.work_package_required'))

    spent_on_field.expect_value((Date.today.beginning_of_week(:sunday) + 3.days).strftime)

    expect(page)
      .not_to have_selector('.ng-spinner-loader')

    wp_field.input_element.click
    wp_field.set_value(other_work_package.subject)

    expect(page)
      .to have_no_content(I18n.t('js.time_entry.work_package_required'))

    comments_field.set_value('Comment for new entry')

    activity_field.input_element.click
    activity_field.set_value(activity.name)

    hours_field.set_value('4')

    sleep(0.1)

    click_button I18n.t('js.label_create')

    my_page.expect_and_dismiss_notification message: I18n.t(:notice_successful_create)

    within entries_area.area do
      expect(page)
        .to have_selector(".fc-content-skeleton td:nth-of-type(5) .fc-event-container .te-calendar--time-entry",
                          text: other_work_package.subject)
    end

    expect(page)
      .to have_content "Total: 9.00"

    expect(TimeEntry.count)
      .to eql 5

    ## Editing an entry

    within entries_area.area do
      find(".fc-content-skeleton td:nth-of-type(3) .fc-event-container .te-calendar--time-entry").click
    end

    expect(page)
      .to have_content(I18n.t('js.time_entry.label'))

    activity_field.input_element.click
    activity_field.set_value(other_activity.name)

    wp_field.input_element.click
    # As the other_work_package now has time logged, it is now considered to be a
    # recent work package.
    within('.ng-dropdown-header') do
      click_link(I18n.t('js.label_recent'))
    end
    wp_field.set_value(other_work_package.subject)

    hours_field.set_value('6')

    comments_field.set_value('Some comment')

    cf_field.set_value('Cf text value')

    click_button 'Save'

    sleep(0.1)
    my_page.expect_and_dismiss_notification message: I18n.t(:notice_successful_update)

    within entries_area.area do
      find(".fc-content-skeleton td:nth-of-type(3) .fc-event-container .te-calendar--time-entry").hover
    end

    expect(page)
      .to have_selector('.ui-tooltip', text: "Work package: ##{other_work_package.id}: #{other_work_package.subject}")

    expect(page)
      .to have_selector('.ui-tooltip', text: "Hours: 6 h")

    expect(page)
      .to have_selector('.ui-tooltip', text: "Activity: #{other_activity.name}")

    expect(page)
      .to have_selector('.ui-tooltip', text: "Comment: Some comment")

    expect(page)
      .to have_content "Total: 12.00"

    ## Removing the time entry

    within entries_area.area do
      find(".fc-content-skeleton td:nth-of-type(6) .fc-event-container .te-calendar--time-entry").click
    end

    click_button 'Delete'
    page.driver.browser.switch_to.alert.accept

    within entries_area.area do
      expect(page)
       .not_to have_selector(".fc-content-skeleton td:nth-of-type(6) .fc-event-container .te-calendar--time-entry")
    end

    expect(page)
      .to have_content "Total: 10.00"

    expect(TimeEntry.where(id: other_visible_time_entry.id))
      .not_to be_exist

    # Removing the widget

    entries_area.remove

    # as the last widget has been removed, the add button is always displayed
    nucleous_area = Components::Grids::GridArea.of(2, 2)
    nucleous_area.expect_to_exist

    within nucleous_area.area do
      expect(page)
        .to have_selector(".grid--widget-add")
    end
  end
end
