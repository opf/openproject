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

describe 'Working Days', js: true do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }
  shared_let(:admin) { create :admin }
  let_schedule(<<~CHART)
    days                  | MTWTFSSmtwtfss |
    earliest_work_package | XXXXX          |
    second_work_package   |    XX..XX      |
    follower              |          XXX   | follows earliest_work_package, follows second_work_package
  CHART

  let(:dialog) { Components::ConfirmationDialog.new }

  current_user { admin }

  before do
    visit admin_settings_working_days_path
  end

  # Using this way instead of Setting.working_days as that is cached.
  def working_days_setting
    Setting.find_by(name: :working_days).value
  end

  it 'contains all defined days from the settings' do
    WeekDay.all.each do |day|
      expect(page).to have_selector('label', text: day.name)
      if day.working
        expect(page).to have_checked_field day.name
      end
    end
  end

  it 'rejects the updates when cancelling the dialog' do
    expect(working_days_setting).to eq([1, 2, 3, 4, 5])

    uncheck 'Monday'
    uncheck 'Friday'

    click_on 'Save'

    perform_enqueued_jobs do
      dialog.cancel
    end

    expect(page).to have_no_selector('.flash.notice')

    expect(working_days_setting).to eq([1, 2, 3, 4, 5])

    expect_schedule(WorkPackage.all, <<~CHART)
      days                  | MTWTFSSmtwtfss |
      earliest_work_package | XXXXX          |
      second_work_package   |    XX..XX      |
      follower              |          XXX   |
    CHART
  end

  it 'updates the values and saves the settings' do
    expect(working_days_setting).to eq([1, 2, 3, 4, 5])

    uncheck 'Monday'
    uncheck 'Friday'

    click_on 'Save'

    perform_enqueued_jobs do
      dialog.confirm
    end

    expect(page).to have_selector('.flash.notice', text: 'Successful update.')
    expect(page).to have_unchecked_field 'Monday'
    expect(page).to have_unchecked_field 'Friday'
    expect(page).to have_unchecked_field 'Saturday'
    expect(page).to have_unchecked_field 'Sunday'
    expect(page).to have_checked_field 'Tuesday'
    expect(page).to have_checked_field 'Wednesday'
    expect(page).to have_checked_field 'Thursday'

    expect(working_days_setting).to eq([2, 3, 4])

    expect_schedule(WorkPackage.all, <<~CHART)
      days                  | MTWTFSSmtwtfssmtwt  |
      earliest_work_package |  XXX....XX          |
      second_work_package   |    X....XXX         |
      follower              |                XXX  |
    CHART

    # The updated work packages will have a journal entry informing about the change
    wp_page = Pages::FullWorkPackage.new(earliest_work_package)
    wp_page.visit!

    wp_page.expect_comment(text: "Working days changed (Monday is now non-working, Friday is now non-working).")
  end

  it 'shows error when non working days are all unset' do
    uncheck 'Monday'
    uncheck 'Tuesday'
    uncheck 'Wednesday'
    uncheck 'Thursday'
    uncheck 'Friday'

    click_on 'Save'

    perform_enqueued_jobs do
      dialog.confirm
    end

    expect(page).to have_selector('.flash.error', text: 'At least one day of the week must be defined as a working day.')
    # Restore the checkboxes to their valid state
    expect(page).to have_checked_field 'Monday'
    expect(page).to have_checked_field 'Tuesday'
    expect(page).to have_checked_field 'Wednesday'
    expect(page).to have_checked_field 'Thursday'
    expect(page).to have_checked_field 'Friday'
    expect(page).to have_unchecked_field 'Saturday'
    expect(page).to have_unchecked_field 'Sunday'
    expect(working_days_setting).to eq([1, 2, 3, 4, 5])

    expect_schedule(WorkPackage.all, <<~CHART)
      days                  | MTWTFSSmtwtfss |
      earliest_work_package | XXXXX          |
      second_work_package   |    XX..XX      |
      follower              |          XXX   |
    CHART
  end

  it 'shows an error when a previous change to the working days configuration isn\'t processed yet' do
    # Have a job already scheduled
    # Attempting to set the job via simply using the UI would require to change the test setup of how
    # delayed jobs are handled.
    ActiveJob::QueueAdapters::DelayedJobAdapter
      .new
      .enqueue(WorkPackages::ApplyWorkingDaysChangeJob.new(user_id: 5))

    uncheck 'Tuesday'
    click_on 'Save'

    # Not executing the background jobs
    dialog.confirm

    expect(page).to have_selector('.flash.error',
                                  text: 'The previous changes to the working days configuration have not been applied yet.')
  end
end
