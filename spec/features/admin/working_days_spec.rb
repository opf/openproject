#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe "Working Days", :js, :with_cuprite do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }
  shared_let(:admin) { create(:admin) }

  let_schedule(<<~CHART)
    days                  | MTWTFSSmtwtfss |
    earliest_work_package | XXXXX          |
    second_work_package   |    XX..XX      |
    follower              |          XXX   | follows earliest_work_package, follows second_work_package
  CHART

  let(:dialog) { Components::ConfirmationDialog.new }
  let(:datepicker) { Components::DatepickerModal.new }

  current_user { admin }

  before do
    visit admin_settings_working_days_and_hours_path
  end

  describe "week days" do
    # Using this way instead of Setting.working_days as that is cached.
    def working_days_setting
      Setting.find_by(name: :working_days).value
    end

    it "contains all defined days from the settings" do
      WeekDay.all.each do |day|
        expect(page).to have_css("label", text: day.name)
        if day.working
          expect(page).to have_checked_field day.name
        end
      end
    end

    it "rejects the updates when cancelling the dialog" do
      expect(working_days_setting).to eq([1, 2, 3, 4, 5])

      uncheck "Monday"
      uncheck "Friday"

      click_on "Apply changes"

      perform_enqueued_jobs do
        dialog.cancel
      end

      expect(page).to have_no_css(".op-toast.-success")

      expect(working_days_setting).to eq([1, 2, 3, 4, 5])

      expect_schedule(WorkPackage.all, <<~CHART)
        days                  | MTWTFSSmtwtfss |
        earliest_work_package | XXXXX          |
        second_work_package   |    XX..XX      |
        follower              |          XXX   |
      CHART
    end

    it "updates the values and saves the settings" do
      expect(working_days_setting).to eq([1, 2, 3, 4, 5])

      uncheck "Monday"
      uncheck "Friday"

      click_on "Apply changes"

      perform_enqueued_jobs do
        dialog.confirm
      end

      expect(page).to have_css(".op-toast.-success", text: "Successful update.")
      expect(page).to have_unchecked_field "Monday"
      expect(page).to have_unchecked_field "Friday"
      expect(page).to have_unchecked_field "Saturday"
      expect(page).to have_unchecked_field "Sunday"
      expect(page).to have_checked_field "Tuesday"
      expect(page).to have_checked_field "Wednesday"
      expect(page).to have_checked_field "Thursday"

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

      wp_page.expect_activity_message(
        "Dates changed by changes to working days (Monday is now non-working, Friday is now non-working)"
      )
    end

    it "shows error when non working days are all unset" do
      uncheck "Monday"
      uncheck "Tuesday"
      uncheck "Wednesday"
      uncheck "Thursday"
      uncheck "Friday"

      click_on "Apply changes"

      perform_enqueued_jobs do
        dialog.confirm
      end

      expect(page).to have_css(".op-toast.-error",
                               text: "At least one day of the week must be defined as a working day.")
      # Restore the checkboxes to their valid state
      expect(page).to have_checked_field "Monday"
      expect(page).to have_checked_field "Tuesday"
      expect(page).to have_checked_field "Wednesday"
      expect(page).to have_checked_field "Thursday"
      expect(page).to have_checked_field "Friday"
      expect(page).to have_unchecked_field "Saturday"
      expect(page).to have_unchecked_field "Sunday"
      expect(working_days_setting).to eq([1, 2, 3, 4, 5])

      expect_schedule(WorkPackage.all, <<~CHART)
        days                  | MTWTFSSmtwtfss |
        earliest_work_package | XXXXX          |
        second_work_package   |    XX..XX      |
        follower              |          XXX   |
      CHART
    end

    it "shows an error when a previous change to the working days configuration isn't processed yet" do
      # Have a job already scheduled
      ActiveJob::Base.disable_test_adapter
      WorkPackages::ApplyWorkingDaysChangeJob.perform_later(user_id: 5)

      uncheck "Tuesday"
      click_on "Apply changes"

      # Not executing the background jobs
      dialog.confirm

      expect(page).to have_css(".op-toast.-error",
                               text: "The previous changes to the working days configuration have not been applied yet.")
    end
  end

  describe "non-working days" do
    shared_let(:non_working_days) do
      [
        create(:non_working_day, date: Date.new(Date.current.year, 6, 10)),
        create(:non_working_day, date: Date.new(Date.current.year, 8, 20)),
        create(:non_working_day, date: Date.new(Date.current.year, 9, 25))
      ]
    end

    it "can add non-working days" do
      # Initial loading can sometimes take a while
      datepicker.open_modal!

      # Check if a date is correctly highlighted after selecting it in different time zones
      datepicker.select_day 5

      # It can cancel and reopen
      within_test_selector("op-datepicker-modal") do
        click_on "Cancel"
      end

      datepicker.open_modal!

      within_test_selector("op-datepicker-modal") do
        fill_in "name", with: "My holiday"
      end

      date1 = NonWorkingDay.maximum(:date).next_week(:monday).next_occurring(:monday)
      datepicker.set_date_input(date1)

      within_test_selector("op-datepicker-modal") do
        click_on "Add"
      end

      expect(page).to have_css(".fc-list-event-title", text: "My holiday")

      # Add a second day
      click_on "Non-working day"

      within_test_selector("op-datepicker-modal") do
        fill_in "name", with: "Another important day"
      end

      date2 = NonWorkingDay.maximum(:date).next_week(:monday).next_occurring(:tuesday)
      datepicker.set_date_input(date2)

      within_test_selector("op-datepicker-modal") do
        click_on "Add"
      end

      click_on "Apply changes"
      click_on "Save and reschedule"

      expect(page).to have_css(".op-toast.-success", text: "Successful update.")

      nwd1 = NonWorkingDay.find_by(name: "My holiday")
      expect(nwd1.date).to eq date1

      nwd2 = NonWorkingDay.find_by(name: "Another important day")
      expect(nwd2.date).to eq date2

      # Check if date and name are entered then close the datepicker
      datepicker.open_modal!
      within_test_selector("op-datepicker-modal") do
        click_on "Add"
      end

      expect(page).to have_css(".flatpickr-calendar", wait: 5)
      datepicker.expect_visible

      within_test_selector("op-datepicker-modal") do
        fill_in "name", with: "Instance-wide NWD"
      end

      datepicker.set_date date2

      within_test_selector("op-datepicker-modal") do
        click_on "Add"
      end
      expect(page).to have_no_css(".flatpickr-calendar")

      expect(page).to have_css(".op-toast", text: /A non-working day for this date exists already/)
    end

    it "deletes a non-working day" do
      non_working_days.each do |nwd|
        expect(page).to have_css("tr", text: nwd.date.strftime("%B %-d, %Y"))
      end

      delete_button = page.first(".op-non-working-days-list--delete-icon .icon-delete", visible: :all)
      delete_button.hover
      delete_button.click

      click_on "Apply changes"

      dialog.confirm

      # Remove the first date
      expect(page).to have_no_css("tr", text: non_working_days.first.date.strftime("%B %-d, %Y"))
      expect(page).to have_css("tr", text: non_working_days.last.date.strftime("%B %-d, %Y"))

      # Show an error when the changes cannot be saved and preserves the modifications upon submit
      errors = ActiveModel::Errors.new(NonWorkingDay.new)
      errors.add(:id, :invalid)

      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(NonWorkingDay)
        .to receive(:errors)
              .and_return(errors)
      # rubocop:enable RSpec/AnyInstance

      delete_button = page.first(".op-non-working-days-list--delete-icon .icon-delete", visible: :all)
      delete_button.hover
      delete_button.click

      click_on "Apply changes"

      dialog.confirm

      # Keep the second date hidden
      expect(page).to have_no_css("tr", text: non_working_days.second.date.strftime("%B %-d, %Y"))
      expect(page).to have_css("tr", text: non_working_days.last.date.strftime("%B %-d, %Y"))
    end
  end

  it "doesn't open a confirmation dialog if no working/non-working days have been modified" do
    create(:non_working_day, date: Date.new(Date.current.year, 6, 10))
    create(:non_working_day, date: Date.new(Date.current.year, 8, 20))
    create(:non_working_day, date: Date.new(Date.current.year, 9, 25))

    click_on "Apply changes"

    # No dialog and saved successfully
    expect(page).to have_css(".op-toast.-success")
  end
end
