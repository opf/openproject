#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

describe 'Working Days', type: :feature, js: true do
  shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }
  shared_let(:admin) { create :admin }
  let(:dialog) { ::Components::ConfirmationDialog.new }

  before do
    login_as(admin)
    visit admin_settings_working_days_path
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
    expect(Setting.working_days).to eq([1, 2, 3, 4, 5])
    uncheck 'Monday'
    uncheck 'Friday'

    click_on 'Save'

    dialog.cancel
    expect(page).to have_no_selector('.flash.notice')

    expect(Setting.working_days).to eq([1, 2, 3, 4, 5])
  end

  it 'updates the values and saves the settings' do
    expect(Setting.working_days).to eq([1, 2, 3, 4, 5])
    uncheck 'Monday'
    uncheck 'Friday'

    click_on 'Save'

    dialog.confirm

    expect(page).to have_selector('.flash.notice', text: 'Successful update.')
    expect(page).to have_unchecked_field 'Monday'
    expect(page).to have_unchecked_field 'Friday'
    expect(page).to have_unchecked_field 'Saturday'
    expect(page).to have_unchecked_field 'Sunday'
    expect(page).to have_checked_field 'Tuesday'
    expect(page).to have_checked_field 'Wednesday'
    expect(page).to have_checked_field 'Thursday'

    RequestStore.clear!
    expect(Setting.working_days).to eq([2, 3, 4])
  end

  it 'shows error when no working days are set' do
    uncheck 'Monday'
    uncheck 'Tuesday'
    uncheck 'Wednesday'
    uncheck 'Thursday'
    uncheck 'Friday'

    click_on 'Save'

    dialog.confirm

    expect(page).to have_selector('.flash.error', text: 'At least one working day needs to be specified.')
    # Restore the checkboxes to their valid state
    expect(page).to have_checked_field 'Monday'
    expect(page).to have_checked_field 'Tuesday'
    expect(page).to have_checked_field 'Wednesday'
    expect(page).to have_checked_field 'Thursday'
    expect(page).to have_checked_field 'Friday'
    expect(page).to have_unchecked_field 'Saturday'
    expect(page).to have_unchecked_field 'Sunday'
    expect(Setting.working_days).to eq([1, 2, 3, 4, 5])
  end
end
