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
require "features/page_objects/notification"
require "features/work_packages/details/inplace_editor/shared_examples"
require "features/work_packages/shared_contexts"
require "support/edit_fields/edit_field"
require "features/work_packages/work_packages_page"

RSpec.describe "date inplace editor", :js, :selenium, with_settings: { date_format: "%Y-%m-%d" } do
  shared_let(:project) { create(:project_with_types, public: true) }
  shared_let(:user) { create(:admin) }
  shared_let(:type) { project.enabled_types.first }
  shared_let(:priority) { create(:default_priority) }
  shared_let(:status) { create(:default_status) }

  shared_let(:date_cf) do
    create(
      :date_wp_custom_field,
      name: "My date",
      types: [type],
      projects: [project]
    )
  end

  let(:work_package) { create(:work_package, project:, start_date: Date.parse("2016-01-02"), duration: nil) }

  let(:work_packages_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new }
  let(:hierarchy) { Components::WorkPackages::Hierarchies.new }

  let(:start_date) { work_packages_page.edit_field(:combinedDate) }
  let(:datepicker) { start_date.datepicker }

  before do
    login_as(user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded
    wait_for_network_idle
  end

  it "can directly set the due date when activating it" do
    start_date.activate!
    start_date.expect_active!

    start_date.enable_due_date

    start_date.datepicker.expect_year "2016"
    start_date.datepicker.expect_month "January"
    start_date.datepicker.select_day "25"

    start_date.datepicker.expect_start_date "2016-01-02"
    start_date.datepicker.expect_due_date "2016-01-25"
    start_date.datepicker.expect_duration 24

    start_date.save!
    start_date.expect_inactive!
    start_date.expect_state_text "2016-01-02 - 2016-01-25"
  end

  it 'can set "today" as a date via the provided link' do
    start_date.activate!
    start_date.expect_active!

    start_date.datepicker.expect_start_date "2016-01-02"
    start_date.datepicker.expect_year work_package.start_date.year
    start_date.datepicker.expect_month work_package.start_date.strftime("%B")
    start_date.datepicker.expect_day work_package.start_date.day

    start_date.datepicker.set_today :start
    start_date.datepicker.expect_start_date Time.zone.today.iso8601

    start_date.datepicker.expect_year Time.zone.today.year
    start_date.datepicker.expect_month Time.zone.today.strftime("%B")
    start_date.datepicker.expect_day Time.zone.today.day

    start_date.save!
    start_date.expect_inactive!
    start_date.expect_state_text "#{Time.zone.today.strftime('%Y-%m-%d')} - no finish date"
  end

  context "with start and end date set" do
    let(:work_package) do
      create(:work_package,
             project:,
             start_date: Date.parse("2016-01-02"),
             due_date: Date.parse("2016-01-25"))
    end

    it "selecting a date before the current start date will keep the finish date" do
      start_date.activate!
      start_date.expect_active!

      start_date.datepicker.expect_year "2016"
      start_date.datepicker.expect_month "January"
      start_date.datepicker.select_day "1"

      start_date.datepicker.expect_start_date "2016-01-01"
      start_date.datepicker.expect_due_date "2016-01-25"
      start_date.datepicker.expect_duration 25

      start_date.save!
      start_date.expect_inactive!
      start_date.expect_state_text "2016-01-01 - 2016-01-25"
    end

    it "selecting a date in between changes the date that is currently in focus" do
      start_date.activate!
      start_date.expect_active!

      start_date.datepicker.expect_year "2016"
      start_date.datepicker.expect_month "January"
      start_date.datepicker.select_day "3"

      start_date.datepicker.expect_start_date "2016-01-03"

      # The inputs have a debounce which we have to wait for before clicking the next field
      sleep 0.25

      # Since the focus shifts automatically, we can directly click again to modify the end date
      start_date.datepicker.select_day "21"

      start_date.datepicker.expect_due_date "2016-01-21"
      start_date.datepicker.expect_duration 19

      start_date.save!
      start_date.expect_inactive!
      start_date.expect_state_text "2016-01-03 - 2016-01-21"
    end

    it "selecting a date after the current finish date will change either start or finish depending on the focus" do
      start_date.activate!
      start_date.expect_active!

      start_date.datepicker.expect_year "2016"
      start_date.datepicker.expect_month "January"

      # Focus the end date field
      start_date.activate_due_date_within_modal
      start_date.datepicker.set_due_date "2016-03-01"

      # Since the end date is focused, the date will become the new end date
      start_date.save!
      start_date.expect_inactive!
      start_date.expect_state_text "2016-01-02 - 2016-03-01"

      # Activating again and now changing the start date to something after the current end date
      start_date.activate!
      start_date.expect_active!

      start_date.datepicker.expect_year "2016"
      start_date.datepicker.expect_month "January"
      start_date.datepicker.set_start_date "2016-04-01"

      # This will set the new start and unset the end date
      start_date.save!
      start_date.expect_inactive!
      start_date.expect_state_text "2016-04-01 - no finish date"
    end
  end

  context "with the start date empty" do
    let(:work_package) { create(:work_package, project:, start_date: nil, duration: nil) }

    it 'can set "today" as a date via the provided link' do
      start_date.activate!
      start_date.expect_active!

      # Wait for the datepicker to be loaded
      sleep 1

      start_date.enable_start_date

      start_date.datepicker.set_today :start
      start_date.datepicker.expect_start_date Time.zone.today.iso8601

      start_date.datepicker.expect_year Time.zone.today.year
      start_date.datepicker.expect_month Time.zone.today.strftime("%B")
      start_date.datepicker.expect_day Time.zone.today.day

      start_date.save!
      start_date.expect_inactive!
      start_date.expect_state_text "#{Time.zone.today.strftime('%Y-%m-%d')} - no finish date"
    end
  end

  it "can set start and due date to the same day" do
    start_date.activate!
    start_date.expect_active!

    # The calendar needs some time to get initialised.
    sleep 2
    start_date.datepicker.expect_visible

    # Due date is hidden behind a button as it is empty
    start_date.enable_due_date
    start_date.set_due_date Time.zone.today

    # Wait for duration to be derived
    start_date.expect_duration /\d+/

    # As the to be selected date is automatically toggled,
    # we can directly set the start date afterwards to the same day
    start_date.expect_start_highlighted
    start_date.set_start_date Time.zone.today
    start_date.expect_duration 1

    start_date.save!
    start_date.expect_inactive!
    start_date.expect_state_text Time.zone.today.strftime("%Y-%m-%d")
  end

  it "can set a negative duration which shows an error message (Regression #44219)" do
    start_date.activate!
    start_date.expect_active!

    start_date.datepicker.enable_due_date

    start_date.datepicker.expect_visible
    start_date.datepicker.set_duration -128
    start_date.datepicker.expect_duration_error "Must be greater than 0."
    start_date.datepicker.expect_start_date_error nil
    start_date.datepicker.expect_due_date_error nil

    start_date.datepicker.set_duration "1.4"
    start_date.datepicker.expect_duration_error "Is not a valid duration."
    start_date.datepicker.expect_start_date_error nil
    start_date.datepicker.expect_due_date_error nil
  end

  it "saves the date when clearing and then confirming" do
    start_date.activate!

    start_date.input_element.click
    start_date.clear with_backspace: true
    start_date.input_element.send_keys :backspace

    sleep 1
    start_date.save!

    work_packages_page.expect_and_dismiss_toaster message: "Successful update."

    start_date.expect_inactive!
    start_date.expect_state_text "no start date"

    work_package.reload
    expect(work_package.start_date).to be_nil
  end

  it "closes the date picker when moving away" do
    wp_table.visit!
    wp_table.open_full_screen_by_doubleclick work_package

    start_date.activate!
    start_date.expect_active!

    page.execute_script("window.history.back()")
    work_packages_page.accept_alert_dialog! if work_packages_page.has_alert_dialog?

    # Ensure no modal survives
    expect(page).to have_no_css(".spot-drop-modal--body")
  end

  # rubocop:disable Layout/LineLength
  context "with a date custom field" do
    let(:cf_field) { EditField.new page, date_cf.attribute_name(:camel_case) }
    let(:datepicker) { Components::BasicDatepicker.new }
    let(:create_page) { Pages::FullWorkPackageCreate.new(project:) }

    it "can handle creating a CF date" do
      create_page.visit!

      type_field = create_page.edit_field(:type)
      type_field.activate!
      type_field.set_value type.name

      cf_field.expect_active!

      # When cancelling, expect there to be no notification
      create_page.cancel!
      create_page.expect_no_toaster type: nil

      create_page.visit!
      cf_field.expect_active!

      # Open date picker
      cf_field.input_element.click
      datepicker.set_date Time.zone.today
      create_page.edit_field(:subject).set_value "My subject!"
      create_page.save!
      create_page.expect_and_dismiss_toaster message: "Successful creation"

      wp = WorkPackage.last
      expect(wp.custom_value_for(date_cf).value).to eq Time.zone.today.iso8601
    end

    it "can set the date via the in-place editing" do
      datepicker.expect_not_visible

      cf_field.activate!
      cf_field.expect_active!

      datepicker.set_date Time.zone.today

      create_page.expect_and_dismiss_toaster message: "Successful update."
      cf_field.expect_inactive!
      cf_field.expect_state_text Time.zone.today.strftime("%Y-%m-%d")
    end
  end

  context "with the work package having no relations whatsoever" do
    let!(:work_package) { create(:work_package, project:) }

    before do
      start_date.activate!
      start_date.expect_active!
    end

    it "does not show a banner with or without manual scheduling" do
      expect(page).not_to have_test_selector("op-modal-banner-warning")
      expect(page).not_to have_test_selector("op-modal-banner-info")

      # When toggling manually scheduled
      start_date.toggle_scheduling_mode

      expect(page).not_to have_test_selector("op-modal-banner-warning")
      expect(page).not_to have_test_selector("op-modal-banner-info")
    end
  end

  context "with the work package being the last in the hierarchy" do
    let!(:parent) { create(:work_package, project:, schedule_manually:, start_date: 1.day.ago, due_date: 5.days.from_now) }
    let!(:work_package) { create(:work_package, project:, schedule_manually:, parent:) }

    before do
      start_date.activate!
      start_date.expect_active!
    end

    context "when work package is manually scheduled" do
      let(:schedule_manually) { true }

      it "shows a banner that the relations are ignored" do
        expect(page).to have_css(test_selector("op-modal-banner-warning").to_s,
                                 text: "Manually scheduled. Dates not affected by relations.\nClick on \"Show relations\" for Gantt overview.",
                                 wait: 5)

        # When toggling manually scheduled
        start_date.toggle_scheduling_mode

        # Expect no banner as it is not automatically schedulable
        expect(page).not_to have_test_selector("op-modal-banner-warning")
        expect(page).not_to have_test_selector("op-modal-banner-info")

        # Toggle back to see the banner again
        start_date.toggle_scheduling_mode

        new_window = window_opened_by { click_on "Show relations" }
        switch_to_window new_window

        wp_table.expect_work_package_listed parent
        wp_table.expect_work_package_listed work_package
        hierarchy.expect_hierarchy_at parent
        hierarchy.expect_leaf_at work_package
        wp_timeline.expect_timeline!
      end
    end

    context "when work package is not manually scheduled" do
      let(:schedule_manually) { false }

      it "shows no banner as the WP is not automatically savable without children or predecessor" do
        expect(page).not_to have_test_selector("op-modal-banner-warning")
        expect(page).not_to have_test_selector("op-modal-banner-info")

        # When toggling manually scheduled
        start_date.toggle_scheduling_mode

        expect(page).to have_css(test_selector("op-modal-banner-warning").to_s,
                                 text: "Manually scheduled. Dates not affected by relations.\nClick on \"Show relations\" for Gantt overview.")
      end
    end
  end

  context "with the work package being a parent" do
    let!(:child) { create(:work_package, project:, start_date: 1.day.ago, due_date: 5.days.from_now) }
    let!(:work_package) do
      wp = create(:work_package, project:, schedule_manually:)
      child.update! parent: wp
      wp
    end

    before do
      start_date.activate!
      start_date.expect_active!
    end

    context "when parent is manually scheduled" do
      let(:schedule_manually) { true }

      it "shows a banner that the relations are ignored" do
        expect(page).to have_css(test_selector("op-modal-banner-warning").to_s,
                                 text: "Manually scheduled. Dates not affected by relations.\nThis has child work packages but their start dates are ignored.")

        # When toggling manually scheduled
        start_date.toggle_scheduling_mode

        # Expect banner to switch
        expect(page).to have_css(test_selector("op-modal-banner-info").to_s,
                                 text: "The dates are determined by child work packages.\nClick on \"Show relations\" for Gantt overview.")

        new_window = window_opened_by { click_on "Show relations" }
        switch_to_window new_window

        wp_table.expect_work_package_listed child
        wp_table.expect_work_package_listed work_package
        wp_timeline.expect_timeline!
      end
    end

    context "when parent is not manually scheduled" do
      let(:schedule_manually) { false }

      it "shows a banner that the dates are are determined by the child" do
        expect(page).to have_css(test_selector("op-modal-banner-info").to_s,
                                 text: "The dates are determined by child work packages.\nClick on \"Show relations\" for Gantt overview.")

        # When toggling manually scheduled
        start_date.toggle_scheduling_mode

        expect(page).to have_css(test_selector("op-modal-banner-warning").to_s,
                                 text: "Manually scheduled. Dates not affected by relations.\nThis has child work packages but their start dates are ignored.")

        new_window = window_opened_by { click_on "Show relations" }
        switch_to_window new_window

        wp_table.expect_work_package_listed child
        wp_timeline.expect_timeline!
      end

      context "and child has working days only set" do
        let!(:child) do
          create(:work_package,
                 project:,
                 ignore_non_working_days: false,
                 start_date: Date.parse("2022-09-27"),
                 due_date: Date.parse("2022-09-29"))
        end

        it "allows switching to manual scheduling to set the ignore NWD (Regression #43933)" do
          expect(page).to have_css(test_selector("op-modal-banner-info").to_s,
                                   text: "The dates are determined by child work packages.\nClick on \"Show relations\" for Gantt overview.")

          # Expect "Working days only" to be checked
          datepicker.expect_working_days_only_disabled
          datepicker.expect_working_days_only true

          # When switching to manually scheduled, "working days only" can be changed
          datepicker.click_manual_scheduling_mode
          expect(page).to have_css(test_selector("op-modal-banner-warning").to_s,
                                   text: "Manually scheduled. Dates not affected by relations.\nThis has child work packages but their start dates are ignored.")

          datepicker.expect_working_days_only_enabled
          datepicker.expect_working_days_only true

          datepicker.toggle_working_days_only
          datepicker.wait_for_preview_update
          datepicker.expect_working_days_only false

          # Reset "working days only" when switching back to automatic scheduling
          datepicker.click_automatic_scheduling_mode
          datepicker.expect_working_days_only_disabled
          datepicker.expect_working_days_only true

          expect(page).to have_css(test_selector("op-modal-banner-info").to_s,
                                   text: "The dates are determined by child work packages.\nClick on \"Show relations\" for Gantt overview.")
        end
      end
    end
  end

  context "with the work package having a precedes relation" do
    let!(:work_package) { create(:work_package, project:, schedule_manually:, start_date: wp_start_date, due_date: wp_due_date) }
    let!(:preceding) { create(:work_package, project:, start_date: 10.days.ago, due_date: 5.days.ago) }

    let!(:relationship) do
      create(:relation,
             from: preceding,
             to: work_package,
             relation_type: Relation::TYPE_PRECEDES)
    end

    before do
      start_date.activate!
      start_date.expect_active!
    end

    context "when work package is manually scheduled" do
      let(:schedule_manually) { true }
      let(:wp_start_date) { nil }
      let(:wp_due_date) { nil }

      it "shows a banner that the relations are ignored" do
        expect(page).to have_css(test_selector("op-modal-banner-warning").to_s,
                                 text: "Manually scheduled. Dates not affected by relations.\nClick on \"Show relations\" for Gantt overview.")

        # When toggling manually scheduled
        start_date.toggle_scheduling_mode

        # Expect new banner info
        expect(page).to have_css(test_selector("op-modal-banner-info").to_s,
                                 text: "The start date is set by a predecessor.\nClick on \"Show relations\" for Gantt overview.")

        new_window = window_opened_by { click_on "Show relations" }
        switch_to_window new_window

        wp_table.expect_work_package_listed preceding
        wp_table.expect_work_package_listed work_package
        wp_timeline.expect_timeline!
      end
    end

    context "when work package is not manually scheduled" do
      let(:schedule_manually) { false }
      let(:wp_start_date) { nil }
      let(:wp_due_date) { nil }

      it "shows a banner that the start date it set by the predecessor" do
        expect(page).to have_css(test_selector("op-modal-banner-info").to_s,
                                 text: "The start date is set by a predecessor.\nClick on \"Show relations\" for Gantt overview.")

        # When toggling manually scheduled
        start_date.toggle_scheduling_mode

        expect(page).to have_css(test_selector("op-modal-banner-warning").to_s,
                                 text: "Manually scheduled. Dates not affected by relations.\nClick on \"Show relations\" for Gantt overview.")
      end
    end

    context "with the work package having a precedes relation which overlaps" do
      let(:schedule_manually) { true }
      let(:wp_start_date) { 6.days.ago }
      let(:wp_due_date) { 1.day.ago }

      it "shows a banner that there is an overlap" do
        expect(page).to have_css(test_selector("op-modal-banner-warning").to_s,
                                 text: "Manually scheduled. Dates not affected by relations.\nOverlaps with at least one predecessor.")

        # When toggling manually scheduled
        start_date.toggle_scheduling_mode

        # Expect new banner info
        expect(page).to have_css(test_selector("op-modal-banner-info").to_s,
                                 text: "The start date is set by a predecessor.\nClick on \"Show relations\" for Gantt overview.")
      end
    end

    context "with the work package having a precedes relation with a gap of over two days" do
      let(:schedule_manually) { true }
      let(:wp_start_date) { 1.day.ago }
      let(:wp_due_date) { 1.day.ago }

      it "shows a banner that there is a gap" do
        expect(page).to have_css(test_selector("op-modal-banner-warning").to_s,
                                 text: "Manually scheduled. Dates not affected by relations.\nThere is a gap between this and all predecessors.")

        # When toggling manually scheduled
        start_date.toggle_scheduling_mode

        # Expect new banner info
        expect(page).to have_css(test_selector("op-modal-banner-info").to_s,
                                 text: "The start date is set by a predecessor.\nClick on \"Show relations\" for Gantt overview.")
      end
    end
  end

  context "with the work package having a follows relation" do
    let!(:work_package) { create(:work_package, project:, schedule_manually:) }
    let!(:following) { create(:work_package, project:, start_date: 5.days.from_now, due_date: 10.days.from_now) }

    let!(:relationship) do
      create(:relation,
             from: following,
             to: work_package,
             relation_type: Relation::TYPE_FOLLOWS)
    end

    before do
      start_date.activate!
      start_date.expect_active!
    end

    context "when work package is manually scheduled" do
      let(:schedule_manually) { true }

      it "shows a banner that the relations are ignored" do
        expect(page).to have_css(test_selector("op-modal-banner-warning").to_s,
                                 text: "Manually scheduled. Dates not affected by relations.\nClick on \"Show relations\" for Gantt overview.")

        # When toggling manually scheduled
        start_date.toggle_scheduling_mode

        # There is no banner
        expect(page).not_to have_test_selector("op-modal-banner-warning")
        expect(page).not_to have_test_selector("op-modal-banner-info")

        # Toggle back to see the banner again
        start_date.toggle_scheduling_mode

        new_window = window_opened_by { click_on "Show relations" }
        switch_to_window new_window

        wp_table.expect_work_package_listed following
        wp_table.expect_work_package_listed work_package
        wp_timeline.expect_timeline!
      end
    end

    context "when work package is not manually scheduled" do
      let(:schedule_manually) { false }

      it "shows no banner as the WP is not automatically savable without children or predecessor" do
        # There is no banner
        expect(page).not_to have_test_selector("op-modal-banner-warning")
        expect(page).not_to have_test_selector("op-modal-banner-info")

        # When toggling manually scheduled
        start_date.toggle_scheduling_mode

        expect(page).to have_css(test_selector("op-modal-banner-warning").to_s,
                                 text: "Manually scheduled. Dates not affected by relations.\nClick on \"Show relations\" for Gantt overview.")
      end
    end
  end
  # rubocop:enable Layout/LineLength

  context "with a negative time zone", driver: :chrome_new_york_time_zone do
    it "can normally select the dates via datepicker (regression #43562)" do
      start_date.activate!
      start_date.expect_active!

      datepicker.expect_start_date("2016-01-02")
      datepicker.expect_duration("")
      datepicker.expect_year "2016"
      datepicker.expect_month "January"

      datepicker.enable_due_date
      datepicker.select_day "25"

      datepicker.expect_start_date("2016-01-02")
      datepicker.expect_due_date("2016-01-25")
      datepicker.expect_duration("24")
      datepicker.expect_year "2016"
      datepicker.expect_month "January"
      datepicker.expect_day "25"

      start_date.save!
      start_date.expect_inactive!
      start_date.expect_state_text "2016-01-02 - 2016-01-25"
    end
  end
end
