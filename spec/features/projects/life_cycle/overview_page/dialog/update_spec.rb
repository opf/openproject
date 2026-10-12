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
require_relative "../shared_context"

RSpec.describe "Edit project phases on project overview page", :js do
  include_context "with seeded projects and phases"

  shared_let(:overview) { create :overview, project: }
  let(:overview_page) { Pages::Projects::Show.new(project) }
  let(:activity_page) { Pages::Projects::Activity.new(project) }
  let(:datepicker) { Components::DatepickerModal.new }

  current_user { admin }

  before do
    overview_page.visit_page
  end

  def formatted_date_range(life_cycle)
    if life_cycle.date_range_set?
      [life_cycle.start_date, life_cycle.finish_date].map { I18n.l(it) }.join("\n-\n")
    else
      "-"
    end
  end

  describe "with the dialog open" do
    context "when all LifeCycleSteps are blank" do
      before do
        Project::Phase.update_all(start_date: nil, finish_date: nil, duration: nil)
        project_life_cycles.each(&:reload)
      end

      it "shows all the Project::Phases without a value" do
        project_life_cycles.each do |life_cycle|
          dialog = overview_page.open_edit_dialog_for_life_cycle(life_cycle)

          dialog.expect_title(life_cycle.name)
          dialog.expect_input("Start date", value: "", disabled: false)
          dialog.expect_input("Finish date", value: "")
          dialog.expect_input("Duration", value: "", disabled: true)

          dialog.submit # Saving the dialog is successful
          dialog.expect_closed
        end

        project_life_cycles.each do |life_cycle|
          overview_page.within_life_cycle_container(life_cycle) do
            expect(page).to have_text "-"
          end
        end
      end
    end

    context "when all Project::Phase have dates set" do
      it "shows and updates them correctly" do
        life_cycle_initiating_was = life_cycle_initiating.dup
        life_cycle_planning_was = life_cycle_planning.dup
        life_cycle_executing_was = life_cycle_executing.dup
        life_cycle_closing_was = life_cycle_closing.dup

        # Set a value for life_cycle_initiating
        dialog = overview_page.open_edit_dialog_for_life_cycle(life_cycle_initiating, wait_angular: true)

        dialog.expect_input("Start date", value: initiating_start_date)
        dialog.expect_input("Finish date", value: initiating_finish_date)
        dialog.expect_input("Duration", value: initiating_duration, disabled: true)

        dialog.set_date_for(values: [initiating_start_date, initiating_finish_date])
        dialog.set_date_for(values: [start_date - 1.week, start_date])
        dialog.expect_input("Duration", value: 8, disabled: true)

        # Saving the dialog is successful
        dialog.submit
        dialog.expect_closed

        # Sidebar is refreshed with the updated values
        project_life_cycles.each do |life_cycle|
          life_cycle.reload

          overview_page.within_life_cycle_container(life_cycle) do
            expect(page).to have_text formatted_date_range(life_cycle)
          end
        end

        # Open the life_cycle_planning dialog
        expected_start_date = start_date + 1.day
        expected_finish_date = expected_start_date + planning_duration - 1.day
        dialog = overview_page.open_edit_dialog_for_life_cycle(life_cycle_planning, wait_angular: true)

        dialog.expect_input("Start date", value: expected_start_date, disabled: true)
        dialog.expect_input("Finish date", value: expected_finish_date)
        dialog.expect_input("Duration", value: planning_duration, disabled: true)

        # The spec uses relative dates. On some occasions, this can mean the expected_start_date
        # is on the first date of a month. The day before that is then not shown at all.
        # And because the date is disabled, flatpickr also does not provide a button to move to the previous
        # month. In total, we cannot check for the date to be disabled in these occasions.
        if datepicker.displays_date?(expected_start_date - 1.day) && !datepicker.has_previous_month_toggle?
          datepicker.expect_disabled(expected_start_date - 1.day)
        end
        datepicker.expect_not_disabled(expected_start_date)

        # Set invalid range (finish date before start date) via input field
        fill_in("Finish date", with: (expected_start_date - 1.day).strftime("%Y-%m-%d"))
          .send_keys(:tab)

        dialog.expect_validation_message(
          "Finish date",
          text: "Finish date must be after the start date."
        )

        # Clear the value of life_cycle_planning
        dialog.clear_dates

        dialog.expect_no_validation_message("Finish date")

        # Saving the dialog is successful
        dialog.submit
        dialog.expect_closed

        # Sidebar is refreshed with the updated values
        project_life_cycles.each do |life_cycle|
          life_cycle.reload

          overview_page.within_life_cycle_container(life_cycle) do
            expect(page).to have_text formatted_date_range(life_cycle)
          end
        end

        activity_page.visit!

        activity_page.show_details

        activity_page.within_journal(number: 1) do
          activity_page.expect_activity("Initiating changed from " \
                                        "#{I18n.l life_cycle_initiating_was.start_date} - " \
                                        "#{I18n.l life_cycle_initiating_was.finish_date} to " \
                                        "#{I18n.l life_cycle_initiating.start_date} - " \
                                        "#{I18n.l life_cycle_initiating.finish_date}")

          activity_page.expect_activity("Planning changed from " \
                                        "#{I18n.l life_cycle_planning_was.start_date} - " \
                                        "#{I18n.l life_cycle_planning_was.finish_date} to " \
                                        "#{I18n.l life_cycle_planning.start_date} - ")

          activity_page.expect_activity("Planning Start Gate changed from " \
                                        "#{I18n.l life_cycle_planning_was.start_date} to " \
                                        "#{I18n.l life_cycle_planning.start_date}")

          activity_page.expect_activity("Planning Finish Gate date deleted " \
                                        "#{I18n.l life_cycle_planning_was.finish_date}")

          activity_page.expect_activity("Executing changed from " \
                                        "#{I18n.l life_cycle_executing_was.start_date} - " \
                                        "#{I18n.l life_cycle_executing_was.finish_date} to " \
                                        "#{I18n.l life_cycle_executing.start_date} - " \
                                        "#{I18n.l life_cycle_executing.finish_date}")

          activity_page.expect_activity("Closing changed from " \
                                        "#{I18n.l life_cycle_closing_was.start_date} - " \
                                        "#{I18n.l life_cycle_closing_was.finish_date} to " \
                                        "#{I18n.l life_cycle_closing.start_date} - " \
                                        "#{I18n.l life_cycle_closing.finish_date}")
        end
      end

      describe "the datepicker interaction" do
        let(:new_start_date) { start_date - 1.week }
        let(:new_finish_date) { start_date }

        it "interconnects the calendar with the date input fields" do
          # Opening the first phase
          dialog = overview_page.open_edit_dialog_for_life_cycle(life_cycle_initiating, wait_angular: true)

          dialog.expect_input("Start date", value: initiating_start_date)
          dialog.expect_input("Finish date", value: initiating_finish_date)
          dialog.expect_input("Duration", value: 2, disabled: true)

          # Update only finish date via calendar (with finish date field active)
          dialog.activate_field("Finish date")
          dialog.set_date_for(values: [new_finish_date])

          dialog.expect_input("Start date", value: initiating_start_date, active: true)
          dialog.expect_input("Finish date", value: new_finish_date)
          dialog.expect_input("Duration", value: 1, disabled: true)

          # Update start date via calendar (with start date field active)
          dialog.activate_field("Start date")
          dialog.set_date_for(values: [new_start_date])

          dialog.expect_input("Start date", value: new_start_date)
          dialog.expect_input("Finish date", value: new_finish_date, active: true)
          dialog.expect_input("Duration", value: 8, disabled: true)

          # Set finish date again via calendar
          dialog.activate_field("Finish date")
          dialog.set_date_for(values: [new_finish_date])

          dialog.expect_input("Start date", value: new_start_date)
          dialog.expect_input("Finish date", value: new_finish_date)
          dialog.expect_input("Duration", value: 8, disabled: true)

          # Clear both date fields via clear buttons
          dialog.clear_dates

          # Set finish date with empty start date via calendar
          dialog.activate_field("Finish date")
          dialog.set_date_for(values: [new_finish_date])

          # The empty start date is focused and the new finish date is filled in
          dialog.expect_input("Start date", value: "", active: true)
          dialog.expect_input("Finish date", value: new_finish_date)
          dialog.expect_input("Duration", value: "", disabled: true)

          # Complete range by setting start date via the calendar
          dialog.set_date_for(values: [new_start_date])

          dialog.expect_input("Start date", value: new_start_date)
          dialog.expect_input("Finish date", value: new_finish_date)
          dialog.expect_input("Duration", value: 8, disabled: true)
        end
      end
    end

    context "when only the first Project::Phase has dates set" do
      around do |example|
        Timecop.travel("2024-08-22T09:22:00Z".to_datetime) { example.run }
      end

      it "shows updates the following Project::Phase correctly" do
        life_cycle_planning.update!(start_date: nil, finish_date: nil, duration: nil)

        # Open the Executing phase after the Planning phase with no dates
        dialog = overview_page.open_edit_dialog_for_life_cycle(life_cycle_executing, wait_angular: true)

        # Editing the start date should be allowed
        dialog.expect_input("Start date", value: executing_start_date)
        dialog.expect_input("Finish date", value: executing_finish_date)
        dialog.expect_input("Duration", value: 2, disabled: true)

        # The earliest enabled date should be after initiating date's finish date
        initiating_finish_date_succesor = initiating_finish_date + 1.day

        datepicker.show_date(initiating_finish_date)
        datepicker.expect_not_disabled(initiating_finish_date)
        datepicker.expect_not_disabled(initiating_finish_date_succesor)

        dialog.close

        # Save the Initiating phase to trigger rescheduling on the cleared Planning phase
        dialog = overview_page.open_edit_dialog_for_life_cycle(life_cycle_initiating, wait_angular: true)

        dialog.submit # Saving the dialog is successful
        dialog.expect_closed

        # Opening the Planning phase with the default start date
        dialog = overview_page.open_edit_dialog_for_life_cycle(life_cycle_planning, wait_angular: true)

        # The start date automatically succeeds the life_cycle_initiating
        dialog.expect_input("Start date", value: initiating_finish_date_succesor, disabled: true)
        dialog.expect_input("Finish date", value: "")
        dialog.expect_input("Duration", value: "", disabled: true)

        datepicker.show_date(initiating_finish_date)
        datepicker.expect_disabled(initiating_finish_date)
        datepicker.expect_not_disabled(initiating_finish_date_succesor)

        retry_block do
          # Set invalid range (finish date before start date) via input field
          fill_in("Finish date", with: initiating_finish_date.strftime("%Y-%m-%d"))
            .send_keys(:tab)

          dialog.expect_validation_message(
            "Finish date",
            text: "Finish date must be after the start date."
          )
        end

        # Correct the finish date to clear validation via the datepicker
        dialog.set_date_for(values: [planning_finish_date])

        dialog.expect_input("Start date", value: initiating_finish_date_succesor, disabled: true)
        dialog.expect_input("Finish date", value: planning_finish_date)
        dialog.expect_input("Duration", value: planning_duration, disabled: true)

        dialog.submit # Saving the dialog is successful
        dialog.expect_closed

        # Sidebar shows the refreshed life_cycle_planning
        life_cycle_planning.reload
        overview_page.within_life_cycle_container(life_cycle_planning) do
          expect(page).to have_text formatted_date_range(life_cycle_planning)
        end

        # Make the Initiating phase incomplete to allow editing the Planning start date
        life_cycle_initiating.update!(start_date: nil)
        dialog = overview_page.open_edit_dialog_for_life_cycle(life_cycle_planning, wait_angular: true)

        # Clear the start date of life_cycle_planning
        dialog.clear_dates(fields: :start_date)

        dialog.submit # Saving the dialog is successful
        dialog.expect_closed

        # Sidebar shows the refreshed life_cycle_planning
        life_cycle_planning.reload
        overview_page.within_life_cycle_container(life_cycle_planning) do
          expect(page).to have_text formatted_date_range(life_cycle_planning)
        end

        # Planning start date is cleared in the database
        expect(life_cycle_planning).to have_attributes(start_date: nil)

        # Saving the Initiating phase will trigger rescheduling and assigns a start date for Planning
        dialog = overview_page.open_edit_dialog_for_life_cycle(life_cycle_initiating, wait_angular: true)

        dialog.submit # Saving the dialog is successful
        dialog.expect_closed

        # Sidebar shows the refreshed life_cycle_planning
        life_cycle_planning.reload
        overview_page.within_life_cycle_container(life_cycle_planning) do
          expect(page).to have_text formatted_date_range(life_cycle_planning)
        end

        # Planning start date is saved in the database
        # Since the Initiating phase is now incomplete without a duration, the planning
        # starts at the same date as the initiating.
        expect(life_cycle_planning.start_date).to eq(initiating_finish_date)
      end
    end

    context "when there is an invalid custom field on the project (Regression#60666)" do
      let(:custom_field) { create(:string_project_custom_field, is_required: true, is_for_all: true) }

      before do
        project.custom_field_values = { custom_field.id => nil }
        project.save(validate: false)
      end

      it "allows saving and closing the dialog without the custom field validation to interfere" do
        dialog = overview_page.open_edit_dialog_for_life_cycle(life_cycle_initiating, wait_angular: true)

        # Saving the dialog is successful
        dialog.submit
        dialog.expect_closed
      end
    end
  end
end
