# frozen_string_literal: true

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

RSpec.describe "Working Days", :js do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

  shared_let(:project) { create(:project) }
  shared_let(:phase_definition1) { create(:project_phase_definition) }
  shared_let(:phase_definition2) { create(:project_phase_definition) }
  shared_let(:phase1_start_date) { Date.new(2026, 10, 5) } # A Monday
  shared_let(:phase1_end_date) { Date.new(2026, 10, 8) }   # A Thursday
  shared_let(:phase2_start_date) { Date.new(2026, 10, 9) } # A Friday
  shared_let(:phase2_end_date) { Date.new(2026, 10, 13) }  # A Tuesday

  # Create consecutive phases with fixed dates
  shared_let(:phase1) do
    create(:project_phase,
           :calculate_duration,
           project:,
           definition: phase_definition1,
           start_date: phase1_start_date,
           finish_date: phase1_end_date)
  end

  shared_let(:phase2) do
    create(:project_phase,
           :calculate_duration,
           project:,
           definition: phase_definition2,
           start_date: phase2_start_date,
           finish_date: phase2_end_date)
  end
  shared_let(:admin) { create(:admin) }

  let_work_packages(<<~TABLE)
    subject               | MTWTFSSmtwtfss | scheduling mode | predecessors
    earliest_work_package | XXXXX          | manual          |
    second_work_package   |    XX..XX      | manual          |
    follower              |          XXX   | automatic       | follows earliest_work_package, follows second_work_package
  TABLE

  let(:datepicker) { Components::DatepickerModal.new }
  let(:project_activity_page) { Pages::Projects::Activity.new(project) }

  current_user { admin }

  before do
    visit admin_settings_working_days_and_hours_path
    # wait for "holidays and closures" calendar to load
    find(".fc-next-button")
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
        within_dialog("Change working days") { click_button "Cancel" }
      end

      expect(page).to have_no_css(".op-toast.-success")

      expect(working_days_setting).to eq([1, 2, 3, 4, 5])

      expect_work_packages(WorkPackage.all, <<~TABLE)
        subject               | MTWTFSSmtwtfss |
        earliest_work_package | XXXXX          |
        second_work_package   |    XX..XX      |
        follower              |          XXX   |
      TABLE
    end

    it "updates the values and saves the settings" do
      expect(working_days_setting).to eq([1, 2, 3, 4, 5])

      uncheck "Monday"
      uncheck "Friday"

      click_on "Apply changes"

      perform_enqueued_jobs do
        within_dialog("Change working days") { click_button "Save and reschedule" }
      end

      expect_flash(message: "Successful update.")
      expect(page).to have_unchecked_field "Monday"
      expect(page).to have_unchecked_field "Friday"
      expect(page).to have_unchecked_field "Saturday"
      expect(page).to have_unchecked_field "Sunday"
      expect(page).to have_checked_field "Tuesday"
      expect(page).to have_checked_field "Wednesday"
      expect(page).to have_checked_field "Thursday"

      expect(working_days_setting).to eq([2, 3, 4])

      expect_work_packages(WorkPackage.all, <<~TABLE)
        subject               | MTWTFSSmtwtfssmtwt  |
        earliest_work_package |  XXX....XX          |
        second_work_package   |    X....XXX         |
        follower              |                XXX  |
      TABLE

      # The updated work packages will have a journal entry informing about the change
      wp_page = Pages::FullWorkPackage.new(earliest_work_package)
      activity_tab = Components::WorkPackages::Activities.new(earliest_work_package)
      wp_page.visit!

      activity_tab.expect_journal_changed_attribute(
        text: "Dates changed by changes to working days (Monday is now non-working, Friday is now non-working)"
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
        within_dialog("Change working days") { click_button "Save and reschedule" }
      end

      expect_flash(type: :error, message: "At least one day of the week must be defined as a working day.")
      # Restore the checkboxes to their valid state
      expect(page).to have_checked_field "Monday"
      expect(page).to have_checked_field "Tuesday"
      expect(page).to have_checked_field "Wednesday"
      expect(page).to have_checked_field "Thursday"
      expect(page).to have_checked_field "Friday"
      expect(page).to have_unchecked_field "Saturday"
      expect(page).to have_unchecked_field "Sunday"
      expect(working_days_setting).to eq([1, 2, 3, 4, 5])

      expect_work_packages(WorkPackage.all, <<~TABLE)
        subject               | MTWTFSSmtwtfss |
        earliest_work_package | XXXXX          |
        second_work_package   |    XX..XX      |
        follower              |          XXX   |
      TABLE
    end

    it "shows an error when a previous change to the working days configuration isn't processed yet",
       with_good_job_batches: [WorkPackages::ApplyWorkingDaysChangeJob] do
      # Have a job already scheduled
      WorkPackages::ApplyWorkingDaysChangeJob.perform_later(user_id: 5)

      uncheck "Tuesday"
      click_on "Apply changes"

      # Not executing the background jobs
      within_dialog("Change working days") { click_button "Save and reschedule" }

      expect_flash(type: :error,
                   message: "The previous changes to the working days configuration have not been applied yet.")
    end

    it "updates project phase date ranges when working days change" do
      # Project phases layout before changes
      #
      #  | name             | MTWTFSSmtwtfssmt | duration |
      #  | Planning         | XXXX             | 4 days   |
      #  | Implementation   |     X..XX        | 3 days   |
      expect(working_days_setting).to eq([1, 2, 3, 4, 5])

      # Change working days configuration
      uncheck "Monday"
      uncheck "Friday"

      click_on "Apply changes"

      perform_enqueued_jobs do
        within_dialog("Change working days") { click_button "Save and reschedule" }
      end

      expect_flash(message: "Successful update.")

      # Expected phase layout after changes
      #
      #  | name             | MTWTFSSmtwtfssmt | duration |
      #  | Planning         |  XXX....X        | 4 days   |
      #  | Implementation   |          XX....X | 3 days   |
      phase1.reload
      phase2.reload

      # Verify phases have been adjusted for the new working days
      # Monday is now non-working so the start date should have moved to Tuesday
      expect(phase1.start_date).to eq(Date.new(2026, 10, 6)) # Tuesday
      # The end date should be adjusted to maintain the same duration in working days
      expect(phase1.finish_date).to eq(Date.new(2026, 10, 13)) # Tuesday

      # Second phase should also be adjusted and remain consecutive with phase1
      expect(phase2.start_date).to eq(Date.new(2026, 10, 14)) # Wednesday
      expect(phase2.finish_date).to eq(Date.new(2026, 10, 20)) # Tuesday

      # Check the journal entries for the phases
      project_activity_page.visit!

      project_activity_page.show_details

      project_activity_page
        .expect_activity("Dates changed by changes to working days (Monday is now non-working, Friday is now non-working)")
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
      datepicker.open_modal!

      # Check if a date is correctly highlighted after selecting it in different time zones
      datepicker.select_day 5
      expect(datepicker).to have_day_selected("5")

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

      expect_flash(message: "Successful update.")

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

      within_dialog("Change working days") { click_button "Save and reschedule" }

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

      within_dialog("Change working days") { click_button "Save and reschedule" }

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
    expect_flash(message: "Successful update.")
  end
end
