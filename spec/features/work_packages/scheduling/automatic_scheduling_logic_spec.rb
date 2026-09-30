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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "support/edit_fields/edit_field"

RSpec.describe "Automatic scheduling logic test cases (WP #61054)", :js, with_settings: { date_format: "%Y-%m-%d" } do
  shared_let(:user) { create(:admin) }

  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:type_milestone) { create(:type_milestone) }
  shared_let(:project) { create(:project, types: [type_bug, type_milestone]) }

  shared_let(:bug_wp) { create(:work_package, project:, type: type_bug) }
  shared_let(:milestone_wp) { create(:work_package, project:, type: type_milestone) }

  # assume sat+sun are non working days
  shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

  before_all do
    set_factory_default(:project_with_types, project)
    set_factory_default(:user, user)
  end

  let(:work_packages_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let(:date_attribute) { :combinedDate }
  let(:date_field) { work_packages_page.edit_field(date_attribute) }
  let(:datepicker) { date_field.datepicker }

  let(:current_user) { user }
  let(:work_package) { bug_wp }

  let(:current_attributes) { {} }

  def apply_and_expect_saved(attributes)
    date_field.save!

    work_packages_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

    work_package.reload

    attributes.each do |attr, value|
      expect(work_package.send(attr))
        .to eq(value), "After saving, expected #{attr} to be #{value.inspect} but got #{work_package.send(attr).inspect}"
    end
  end

  before do
    Setting.available_languages << current_user.language
    I18n.locale = current_user.language
    work_package.update_columns(current_attributes) if current_attributes.any?
    login_as(current_user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded
  end

  def open_date_picker
    date_field.activate!
    date_field.expect_active!
    # Wait for the datepicker to be initialized
    datepicker.expect_visible
  end

  describe "Scenario 25: Manual to automatic with no predecessors or children" do
    context "when there are no predecessors or children" do
      let(:current_attributes) do
        {
          start_date: Date.parse("2025-01-08"),
          due_date: Date.parse("2025-01-10"),
          duration: 3,
          schedule_manually: true
        }
      end

      it "cannot change scheduling mode to automatic" do
        open_date_picker
        datepicker.expect_manual_scheduling_mode
        datepicker.expect_working_days_only_checkbox_visible

        datepicker.toggle_scheduling_mode
        datepicker.expect_automatic_scheduling_mode

        datepicker.expect_no_working_days_only_checkbox_visible
        datepicker.expect_save_button_disabled
      end
    end
  end

  describe "Scenario 11 (GANTT/Team planner)" do
    context "when moving the left handle one day to the right" do
      it "reduces the duration by one day", skip: "to be implemented later"
    end
  end

  describe "Scenario 12 (GANTT/Team planner)" do
    context "when moving a work package to the right" do
      it "changes to later dates and keeps duration", skip: "to be implemented later"
    end
  end

  describe "Scenario 12bis (GANTT/Team planner)" do
    context "when moving a work package to the left" do
      it "changes to earlier dates and keeps duration", skip: "to be implemented later"
    end
  end

  describe "Scenario 26: Add a predecessor" do
    context "when adding a predecessor to a work package" do
      let_work_packages(<<~TABLE)
        hierarchy          | start date | due date   | scheduling mode
        future predecessor |            | 2025-01-02 | manual
        work package       | 2025-01-08 | 2025-01-10 | manual
      TABLE

      it "changes the work package dates to start right after its predecessor" do
        # add predecessor
        work_packages_page.visit_tab!("relations")
        work_packages_page.relations_tab.add_predecessor(future_predecessor)

        # expect automatic with dates updated
        open_date_picker
        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_start_date "2025-01-03", disabled: true
        datepicker.expect_due_date "2025-01-07", disabled: false
        datepicker.expect_duration "3"
      end
    end
  end

  describe "Scenario 27a: Manual to automatic with multiple predecessors (no lag)" do
    context "when switching a work package with predecessors to automatic scheduling mode" do
      let_work_packages(<<~TABLE)
        hierarchy         | start date | due date   | scheduling mode | predecessors
        predecessor A     |            | 2024-12-30 | manual          |
        predecessor B     |            | 2025-01-02 | manual          |
        work package      | 2025-01-08 | 2025-01-10 | manual          | predecessor A, predecessor B
      TABLE

      it "changes the work package dates to start right after its closest predecessor" do
        open_date_picker
        datepicker.expect_manual_scheduling_mode

        datepicker.toggle_scheduling_mode
        datepicker.expect_automatic_scheduling_mode

        datepicker.expect_start_date "2025-01-03", disabled: true
        datepicker.expect_due_date "2025-01-07", disabled: false
        datepicker.expect_duration "3", disabled: false

        apply_and_expect_saved(
          start_date: Date.parse("2025-01-03"),
          due_date: Date.parse("2025-01-07"),
          duration: 3,
          schedule_manually: false
        )
      end
    end
  end

  describe "Scenario 27b: Manual to automatic with multiple predecessors (with lag)" do
    context "when switching a work package with predecessors with lag to automatic scheduling mode" do
      let_work_packages(<<~TABLE)
        hierarchy         | start date | due date   | scheduling mode | predecessors
        predecessor A     |            | 2024-12-30 | manual          |
        predecessor B     |            | 2025-01-02 | manual          |
        work package      | 2025-01-08 | 2025-01-10 | manual          | predecessor A with lag 14, predecessor B
      TABLE

      it "changes the work package dates to start right after its closest predecessor" do
        open_date_picker
        datepicker.expect_manual_scheduling_mode

        datepicker.toggle_scheduling_mode
        datepicker.expect_automatic_scheduling_mode

        datepicker.expect_start_date "2025-01-20", disabled: true
        datepicker.expect_due_date "2025-01-22", disabled: false
        datepicker.expect_duration "3", disabled: false

        apply_and_expect_saved(
          start_date: Date.parse("2025-01-20"),
          due_date: Date.parse("2025-01-22"),
          duration: 3,
          schedule_manually: false
        )
      end
    end
  end

  describe "Scenario 28: Add children (parent in manual originally; children all manual, all in working days only)" do
    context "when adding first children to a work package" do
      let_work_packages(<<~TABLE)
        subject      | start date | due date   | scheduling mode | days counting
        work package | 2025-01-08 | 2025-01-10 | manual          | working days only
        child 1      | 2025-01-16 | 2025-01-20 | manual          | working days only
        child 2      | 2025-01-21 | 2025-01-24 | manual          | working days only
      TABLE

      it "switches its scheduling mode to automatic" do
        # add children
        work_packages_page.visit_tab!("relations")
        work_packages_page.relations_tab.add_existing_child(child1)
        work_packages_page.relations_tab.add_existing_child(child2)

        # expect automatic with dates from children and working days only checked
        open_date_picker

        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_start_date "2025-01-16", disabled: true
        datepicker.expect_due_date "2025-01-24", disabled: true
        datepicker.expect_duration "7", disabled: true
        datepicker.expect_working_days_only_disabled
        datepicker.expect_working_days_only true
        datepicker.expect_banner_text I18n.t("work_packages.datepicker_modal.banner.title.automatic_with_children")
      end
    end
  end

  describe "Scenario 29: Add children (parent in manual originally; children all manual, mixed working days)" do
    context "when adding first children to a work package, one having working days only unchecked" do
      let_work_packages(<<~TABLE)
        subject      | start date | due date   | scheduling mode | days counting
        work package | 2025-01-15 | 2025-01-17 | manual          | working days only
        child 1      | 2025-01-16 | 2025-01-20 | manual          | working days only
        child 2      | 2025-01-21 | 2025-01-26 | manual          | all days
      TABLE

      it "switches its scheduling mode to automatic with working days only unchecked" do
        # add children
        work_packages_page.visit_tab!("relations")
        work_packages_page.relations_tab.add_existing_child(child1)
        work_packages_page.relations_tab.add_existing_child(child2)

        # expect automatic with dates from children and working days only unchecked
        open_date_picker

        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_start_date "2025-01-16", disabled: true
        datepicker.expect_due_date "2025-01-26", disabled: true
        datepicker.expect_duration "11", disabled: true
        datepicker.expect_working_days_only_disabled
        datepicker.expect_working_days_only false
        datepicker.expect_banner_text I18n.t("work_packages.datepicker_modal.banner.title.automatic_with_children")
      end
    end
  end

  describe "Scenario 30: Add children to a successor (start date derived children instead of predecessor)" do
    context "when adding manually scheduled children to an automatically scheduled work package being a successor" do
      let_work_packages(<<~TABLE)
        subject      | start date | due date   | scheduling mode | days counting     | predecessors
        predecessor  | 2025-01-10 | 2025-01-14 | manual          | working days only |
        work package | 2025-01-15 | 2025-01-17 | automatic       | working days only | predecessor
        child 1      | 2025-01-16 | 2025-01-20 | manual          | working days only |
        child 2      | 2025-01-21 | 2025-01-26 | manual          | all days          |
      TABLE

      it "updates its duration and dates based on the children dates, not based on its predecessors dates" do
        # add children
        work_packages_page.visit_tab!("relations")
        work_packages_page.relations_tab.add_existing_child(child1)
        work_packages_page.relations_tab.add_existing_child(child2)

        # expect automatic with dates from children and working days only checked
        open_date_picker

        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_start_date "2025-01-16", disabled: true
        datepicker.expect_due_date "2025-01-26", disabled: true
        datepicker.expect_duration "11", disabled: true
        datepicker.expect_working_days_only_disabled
        datepicker.expect_working_days_only false
        datepicker.expect_banner_text I18n.t("work_packages.datepicker_modal.banner.title.automatic_with_children")
      end
    end
  end

  describe "Scenario 30a/30b: Automatically-scheduled successor with children loses all its children" do
    shared_let_work_packages(<<~TABLE)
      hierarchy    | start date | due date   | scheduling mode | days counting     | predecessors
      predecessor  | 2025-01-10 | 2025-01-14 | manual          | working days only |
      work package | 2025-01-16 | 2025-01-28 | automatic       | all days          | predecessor
        child 1    | 2025-01-16 | 2025-01-20 | manual          | all days          |
        child 2    | 2025-01-21 | 2025-01-28 | manual          | working days only |
    TABLE

    context "when removing all children (child 1 then child 2) from an automatically scheduled work package being a successor" do
      it "ends up with duration and 'working days only' attributes based on last removed child (child 2) " \
         "and start date based on the predecessor" do
        work_packages_page.visit_tab!("relations")
        # remove child 1, and then child 2
        work_packages_page.relations_tab.remove_child(child1)
        work_packages_page.relations_tab.remove_child(child2)

        open_date_picker

        # parent gets properties from last removed child: child 2
        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_start_date "2025-01-15", disabled: true
        datepicker.expect_due_date "2025-01-22", disabled: false
        datepicker.expect_duration "6"
        datepicker.expect_working_days_only_enabled
        datepicker.expect_working_days_only true
        datepicker.expect_banner_text I18n.t("work_packages.datepicker_modal.banner.title.automatic_with_predecessor")
      end
    end

    context "when removing all children (child 2 then child 1) from an automatically scheduled work package being a successor" do
      it "ends up with duration 'working days only' attributes based on last removed child (child 1) " \
         "and start date based on the predecessor" do
        work_packages_page.visit_tab!("relations")
        # remove child 2, and then child 1
        work_packages_page.relations_tab.remove_child(child2)
        work_packages_page.relations_tab.remove_child(child1)

        open_date_picker

        # parent gets properties from last removed child: child 1
        datepicker.expect_automatic_scheduling_mode
        datepicker.expect_start_date "2025-01-15", disabled: true
        datepicker.expect_due_date "2025-01-19", disabled: false
        datepicker.expect_duration "5"
        datepicker.expect_working_days_only_enabled
        datepicker.expect_working_days_only false
        datepicker.expect_banner_text I18n.t("work_packages.datepicker_modal.banner.title.automatic_with_predecessor")
      end
    end
  end

  describe "Scenario 32: Switch parent with predecessor and children to manual" do
    context "when switching a work package with predecessors and children to manual scheduling mode" do
      shared_let_work_packages(<<~TABLE)
        hierarchy    | start date | due date   | scheduling mode | days counting     | predecessors
        predecessor  | 2025-01-24 | 2025-01-26 | manual          | working days only |
        work package | 2025-01-27 | 2025-02-06 | automatic       | all days          | predecessor
          child 1    | 2025-01-27 | 2025-01-29 | automatic       | all days          |
          child 2    | 2025-01-30 | 2025-02-06 | automatic       | working days only | child 1
      TABLE

      it "keeps its dates and properties, and also switches the first child to manual scheduling mode" do
        open_date_picker
        datepicker.expect_automatic_scheduling_mode

        datepicker.toggle_scheduling_mode
        datepicker.expect_manual_scheduling_mode

        datepicker.expect_start_date "2025-01-27"
        datepicker.expect_due_date "2025-02-06"
        datepicker.expect_duration "11"
        datepicker.expect_working_days_only_enabled
        datepicker.expect_working_days_only false

        apply_and_expect_saved(
          start_date: Date.parse("2025-01-27"),
          due_date: Date.parse("2025-02-06"),
          duration: 11,
          schedule_manually: true
        )
        expect(child1.reload.schedule_manually).to be(true)
        expect(child2.reload.schedule_manually).to be(false)
      end
    end
  end

  describe "Bug #62261: Invalid error displayed when switching parent to automatic" do
    context "when changing dates to the ones that would be computed by automatic mode and then switching to automatic" do
      let_work_packages(<<~TABLE)
        hierarchy    | start date | due date   | scheduling mode
        work package | 2025-01-27 | 2025-02-06 | manual
          child      |            |            | manual
      TABLE

      it "does not display a 'read-only' error" do
        open_date_picker
        datepicker.set_start_date("")
        datepicker.set_due_date("")

        datepicker.toggle_scheduling_mode

        datepicker.expect_start_date "", disabled: true
        datepicker.expect_due_date "", disabled: true
        read_only_error = I18n.t("activerecord.errors.messages.error_readonly")
        expect(datepicker.container).to have_no_text(/#{Regexp.escape(read_only_error)}/i)

        apply_and_expect_saved(
          start_date: nil,
          due_date: nil,
          duration: nil,
          schedule_manually: false
        )
      end
    end

    context "when manually changing dates of an automatically scheduled successor, and then switch back to automatic" do
      let_work_packages(<<~TABLE)
        subject      | start date | due date   | scheduling mode | predecessors
        predecessor  | 2025-01-14 | 2025-01-16 | manual          |
        work package | 2025-01-17 | 2025-01-17 | automatic       | predecessor
      TABLE

      it "does not display a 'must be set to a later date' error" do
        open_date_picker
        datepicker.toggle_scheduling_mode
        datepicker.expect_manual_scheduling_mode

        # change dates in manual mode
        datepicker.set_start_date("2025-01-06")
        datepicker.set_due_date("2025-01-20")

        datepicker.expect_start_date "2025-01-06"
        datepicker.expect_due_date "2025-01-20"
        datepicker.expect_duration "11"

        # switch back to automatic
        datepicker.toggle_scheduling_mode
        datepicker.expect_automatic_scheduling_mode

        # start date should be derived from predecessors,
        # while the changed finish date is kept and a new duration calculated
        datepicker.expect_start_date "2025-01-17", disabled: true
        datepicker.expect_due_date "2025-01-20", disabled: false
        datepicker.expect_duration "2"

        expect(datepicker.container).to have_no_text(/Can only be set to ....-..-.. or later/i)

        apply_and_expect_saved(
          start_date: Date.parse("2025-01-17"),
          due_date: Date.parse("2025-01-20"),
          duration: 2,
          schedule_manually: false
        )
      end
    end
  end
end
