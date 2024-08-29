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

RSpec.describe "Work package timeline date formatting",
               :js,
               :selenium,
               with_settings: { date_format: "%Y-%m-%d" } do
  shared_let(:type) { create(:type_bug, color: create(:color_green)) }
  shared_let(:project) { create(:project, types: [type], enabled_module_names: %i[work_package_tracking gantt]) }
  shared_let(:start_date) { Date.parse("2020-12-31") }
  shared_let(:due_date) { Date.parse("2021-01-01") }
  shared_let(:duration) { due_date - start_date + 1 }

  shared_let(:work_package) do
    create(:work_package,
           project:,
           type:,
           start_date:,
           due_date:,
           duration:,
           subject: "My subject")
  end

  shared_let(:work_package_with_non_working_days) do
    create(:work_package,
           project:,
           type:,
           duration: 5,
           subject: "My Subject 2")
  end

  shared_let(:work_package_without_non_working_days) do
    create(:work_package,
           project:,
           type:,
           duration: 5,
           ignore_non_working_days: true,
           subject: "Work Package ignoring non working days")
  end

  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(project) }
  let!(:query_tl) do
    query = build(:query_with_view_gantt, user: current_user, project:)
    query.column_names = ["id", "type", "subject"]
    query.filters.clear
    query.timeline_visible = true
    query.timeline_zoom_level = "days"
    query.name = "Query with Timeline"

    query.save!
    query
  end

  def expect_date_week(date, expected_week)
    week = page.evaluate_script <<~JS
      moment('#{date}').format('ww');
    JS

    expect(week).to eq(expected_week)
  end

  before do
    login_as current_user

    wp_timeline.visit_query query_tl
  end

  describe "with default settings",
           with_settings: { start_of_week: "", first_week_of_year: "" } do
    before do
      wp_timeline.expect_timeline!
    end

    context "with german locale user" do
      let(:current_user) { create(:admin, language: "de") }

      it "shows german ISO dates" do
        # expect moment to return week 53 for start date
        expect_date_week work_package.start_date.iso8601, "53"
        expect_date_week work_package.due_date.iso8601, "53"
        # Monday, 4th of january is the first week
        expect_date_week "2021-01-04", "01"
      end
    end

    context "with english locale user" do
      let(:current_user) { create(:admin, language: "en") }

      it "shows english ISO dates" do
        # expect moment to return week 01 for start date
        expect_date_week work_package.start_date.iso8601, "01"
        expect_date_week work_package.due_date.iso8601, "01"
        # Monday, 4th of january is the second week
        expect_date_week "2021-01-04", "02"
      end
    end

    context "with weekdays defined" do
      let(:current_user) { create(:admin, language: "en") }

      shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }
      shared_let(:non_working_day) do
        create(:non_working_day,
               date: "28-12-2020")
      end

      it "shows them as disabled" do
        expect_date_week work_package.start_date.iso8601, "01"

        expect(page).to have_test_selector("wp-timeline--non-working-day_27-12-2020")
        expect(page).to have_test_selector("wp-timeline--non-working-day_2-1-2021")
        expect(page).to have_test_selector("wp-timeline--non-working-day_28-12-2020")

        expect(page).not_to have_test_selector("wp-timeline--non-working-day_29-12-2020")
        expect(page).not_to have_test_selector("wp-timeline--non-working-day_30-12-2020")
        expect(page).not_to have_test_selector("wp-timeline--non-working-day_31-12-2020")
        expect(page).not_to have_test_selector("wp-timeline--non-working-day_1-1-2021")
      end
    end
  end

  describe "with US/CA settings",
           # According to our documentation:
           # https://www.openproject.org/docs/system-admin-guide/calendars-and-dates/#date-format
           with_settings: { start_of_week: "7", first_week_of_year: "6" } do
    let(:current_user) { create(:admin) }

    it "shows english ISO dates" do
      expect(page).to have_css(".wp-timeline--header-element", text: "01")
      expect(page).to have_css(".wp-timeline--header-element", text: "02")

      # The last weekday determines whether there are 52 or 53 weeks
      # Only if the last day in the year is exactly the day before the day configured to be
      # the first week of the year's determining weekday are there 52 weeks.
      weekday_of_last_day = Date.new(Date.current.year, 12, 31).wday
      number_of_weeks = if weekday_of_last_day == (Setting.first_week_of_year.to_i - 1)
                          52
                        else
                          53
                        end

      expect(page).to have_css(".wp-timeline--header-element", text: number_of_weeks)
      expect(page).to have_no_css(".wp-timeline--header-element", text: number_of_weeks + 1)

      # expect moment to return week 01 for start date and due date
      expect_date_week work_package.start_date.iso8601, "01"
      expect_date_week work_package.due_date.iso8601, "01"
      # First sunday in january is in second week
      expect_date_week "2021-01-03", "02"
    end
  end

  describe "setting dates" do
    shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }
    let(:current_user) { create(:admin) }
    let(:row) { wp_timeline.timeline_row work_package_with_non_working_days.id }

    it "today_line is in view" do
      row.wait_until_hoverable
      today_line_offsetLeft = page.evaluate_script <<~JS
        document.getElementById('wp-timeline-static-element-today-line').offsetLeft
      JS
      timeline_side_scrollLeft = page.evaluate_script <<~JS
        document.getElementsByClassName('work-packages-tabletimeline--timeline-side')[0].scrollLeft
      JS
      timeline_side_clientWidth = page.evaluate_script <<~JS
        document.getElementsByClassName('work-packages-tabletimeline--timeline-side')[0].clientWidth
      JS
      expect(today_line_offsetLeft).to be_between(timeline_side_scrollLeft, timeline_side_scrollLeft + timeline_side_clientWidth)
    end

    shared_let(:non_working_day) do
      create(:non_working_day,
             date: "06-01-2021")
    end

    shared_examples "sets dates, duration and displays bar" do
      it "sets dates, duration and duration bar" do
        subject

        row.expect_bar(duration: expected_bar_duration)
        row.expect_labels left: nil,
                          right: nil,
                          farRight: expected_label

        row.expect_hovered_labels left: expected_start_date.iso8601,
                                  right: expected_due_date.iso8601

        target_wp.reload.tap do |wp|
          expect(wp.start_date).to eq(expected_start_date)
          expect(wp.due_date).to eq(expected_due_date)
          expect(wp.duration).to eq(expected_duration)
        end
      end
    end

    context "with an existing duration only" do
      before do
        # Reset dates on each run
        work_package_with_non_working_days.update({ start_date: nil, due_date: nil, duration: 5 })
      end

      it "displays the hover bar correctly" do
        # Expect no hover bar when hovering over a non working day
        row.hover_bar(offset_days: -2)
        row.expect_no_hovered_bar

        # Expect timeline bar when clicking on a non working day
        row.click_bar(offset_days: -2)
        row.expect_no_bar

        # Expect hovered bar size to equal duration
        row.hover_bar(offset_days: -1)
        row.expect_hovered_bar(duration: work_package_with_non_working_days.duration)

        # Expect hovered bar size to equal duration + non working days
        # when the hovered bar passes through non working days
        row.hover_bar(offset_days: 0)
        row.expect_hovered_bar(duration: work_package_with_non_working_days.duration + 2)
      end

      describe "set the start, due date while preserving duration" do
        subject { row.click_bar(offset_days: -1) }

        it_behaves_like "sets dates, duration and displays bar" do
          let(:target_wp) { work_package_with_non_working_days }
          let(:expected_bar_duration) { work_package_with_non_working_days.duration }
          let(:expected_start_date) { Date.parse("2021-01-04") }
          let(:expected_due_date) { Date.parse("2021-01-08") }
          let(:expected_duration) { 4 }
          let(:expected_label) { work_package_with_non_working_days.subject }
        end
      end

      describe "set the start, due date while preserving duration over the weekend" do
        subject { row.click_bar }

        it_behaves_like "sets dates, duration and displays bar" do
          let(:target_wp) { work_package_with_non_working_days }
          let(:expected_bar_duration) { work_package_with_non_working_days.duration + 2 }
          let(:expected_start_date) { Date.parse("2021-01-05") }
          let(:expected_due_date) { Date.parse("2021-01-11") }
          let(:expected_duration) { 4 }
          let(:expected_label) { work_package_with_non_working_days.subject }
        end
      end

      describe "sets the start, due dates while preserving duration on a drag and drop create" do
        subject { row.drag_and_drop(offset_days: -1, days: 5) }

        it_behaves_like "sets dates, duration and displays bar" do
          let(:target_wp) { work_package_with_non_working_days }
          let(:expected_bar_duration) { work_package_with_non_working_days.duration }
          let(:expected_start_date) { Date.parse("2021-01-04") }
          let(:expected_due_date) { Date.parse("2021-01-08") }
          let(:expected_duration) { 4 }
          let(:expected_label) { work_package_with_non_working_days.subject }
        end
      end

      describe "sets the start, due dates while preserving duration on a drag and drop create over the weekend" do
        subject { row.drag_and_drop(days: 7) }

        it_behaves_like "sets dates, duration and displays bar" do
          let(:target_wp) { work_package_with_non_working_days }
          let(:expected_bar_duration) { work_package_with_non_working_days.duration + 2 }
          let(:expected_start_date) { Date.parse("2021-01-05") }
          let(:expected_due_date) { Date.parse("2021-01-11") }
          let(:expected_duration) { 4 }
          let(:expected_label) { work_package_with_non_working_days.subject }
        end
      end

      describe "sets the start, due dates and duration on a drag and drop create over the weekend" do
        subject { row.drag_and_drop(days: 8) }

        it_behaves_like "sets dates, duration and displays bar" do
          let(:target_wp) { work_package_with_non_working_days }
          let(:expected_bar_duration) { work_package_with_non_working_days.duration + 3 }
          let(:expected_start_date) { Date.parse("2021-01-05") }
          let(:expected_due_date) { Date.parse("2021-01-12") }
          let(:expected_duration) { 5 }
          let(:expected_label) { work_package_with_non_working_days.subject }
        end
      end

      it "cancels when the drag starts or finishes on a weekend" do
        # Finish on the weekend
        row.drag_and_drop(days: 5)

        row.expect_no_bar
        expect { work_package_with_non_working_days.reload }.not_to change { work_package_with_non_working_days }

        # Start on the weekend
        row.drag_and_drop(offset_days: -2, days: 5)

        row.expect_no_bar
        expect { work_package_with_non_working_days.reload }.not_to change { work_package_with_non_working_days }
      end

      context "when ignore_non_working_days is true" do
        let(:row) { wp_timeline.timeline_row work_package_without_non_working_days.id }

        describe "sets the start, due dates and duration on a drag and drop create over the weekend" do
          subject { row.drag_and_drop(days: 8) }

          it_behaves_like "sets dates, duration and displays bar" do
            let(:target_wp) { work_package_without_non_working_days }
            let(:expected_bar_duration) { work_package_without_non_working_days.duration + 3 }
            let(:expected_start_date) { Date.parse("2021-01-05") }
            let(:expected_due_date) { Date.parse("2021-01-12") }
            let(:expected_duration) { 8 }
            let(:expected_label) { work_package_without_non_working_days.subject }
          end
        end
      end
    end
  end
end
