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

RSpec.describe 'Work package timeline date formatting',
               with_settings: { date_format: '%Y-%m-%d' },
               js: true,
               selenium: true do
  shared_let(:type) { create(:type_bug, color: create(:color_green)) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:start_date) { Date.parse('2020-12-31') }
  shared_let(:due_date) { Date.parse('2021-01-01') }
  shared_let(:duration) { due_date - start_date + 1 }

  shared_let(:work_package) do
    create :work_package,
           project:,
           type:,
           start_date:,
           due_date:,
           duration:,
           subject: 'My subject'
  end

  shared_let(:work_package_with_non_working_days) do
    create :work_package,
           project:,
           type:,
           duration: 5,
           subject: 'My Subject 2'
  end

  shared_let(:work_package_without_non_working_days) do
    create :work_package,
           project:,
           type:,
           duration: 5,
           ignore_non_working_days: true,
           subject: 'Work Package ignoring non working days'
  end

  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(project) }
  let!(:query_tl) do
    query = build(:query, user: current_user, project:)
    query.column_names = ['id', 'type', 'subject']
    query.filters.clear
    query.timeline_visible = true
    query.timeline_zoom_level = 'days'
    query.name = 'Query with Timeline'

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

  describe 'with default settings',
           with_settings: { start_of_week: '', first_week_of_year: '' } do
    context 'with english locale user' do
      let(:current_user) { create :admin, language: 'en' }

      it 'shows english ISO dates' do
        # expect moment to return week 01 for start date
        expect_date_week work_package.start_date.iso8601, '01'
        expect_date_week work_package.due_date.iso8601, '01'
        # Monday, 4th of january is the second week
        expect_date_week '2021-01-04', '02'
      end
    end

    context 'with german locale user' do
      let(:current_user) { create :admin, language: 'de' }

      it 'shows german ISO dates' do
        expect(page).to have_selector('.wp-timeline--header-element', text: '52')
        expect(page).to have_selector('.wp-timeline--header-element', text: '53')

        # expect moment to return week 53 for start date
        expect_date_week work_package.start_date.iso8601, '53'
        expect_date_week work_package.due_date.iso8601, '53'
        # Monday, 4th of january is the first week
        expect_date_week '2021-01-04', '01'
      end
    end

    context 'with weekdays defined' do
      let(:current_user) { create :admin, language: 'en' }

      shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }
      shared_let(:non_working_day) do
        create(:non_working_day,
               date: '28-12-2020')
      end

      it 'shows them as disabled' do
        expect_date_week work_package.start_date.iso8601, '01'

        expect(page).to have_selector('[data-qa-selector="wp-timeline--non-working-day_27-12-2020"]')
        expect(page).to have_selector('[data-qa-selector="wp-timeline--non-working-day_2-1-2021"]')
        expect(page).to have_selector('[data-qa-selector="wp-timeline--non-working-day_28-12-2020"]')

        expect(page).to have_no_selector('[data-qa-selector="wp-timeline--non-working-day_29-12-2020"]')
        expect(page).to have_no_selector('[data-qa-selector="wp-timeline--non-working-day_30-12-2020"]')
        expect(page).to have_no_selector('[data-qa-selector="wp-timeline--non-working-day_31-12-2020"]')
        expect(page).to have_no_selector('[data-qa-selector="wp-timeline--non-working-day_1-1-2021"]')
      end
    end
  end

  describe 'with US/CA settings',
           with_settings: { start_of_week: '7', first_week_of_year: '1' } do
    let(:current_user) { create :admin }

    it 'shows english ISO dates' do
      expect(page).to have_selector('.wp-timeline--header-element', text: '01')
      expect(page).to have_selector('.wp-timeline--header-element', text: '02')

      # According to the Canadian locale (https://savvytime.com/week-number/canada/2022)
      # the first week of the year is the week where 1st of January falls.
      # If that is last year, then we need to add an offset +1 week to the total number of years.
      current_year = Date.current.year
      week_offset = current_year - Date.new(current_year, 1, 1).beginning_of_week.year

      weeks_this_year = Date.new(current_year, 12, 28).cweek + week_offset
      expect(page).not_to have_selector('.wp-timeline--header-element', text: weeks_this_year + 1)

      # expect moment to return week 01 for start date and due date
      expect_date_week work_package.start_date.iso8601, '01'
      expect_date_week work_package.due_date.iso8601, '01'
      # First sunday in january is in second week
      expect_date_week '2021-01-03', '02'
    end
  end

  describe 'setting dates' do
    shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }
    let(:current_user) { create :admin }
    let(:row) { wp_timeline.timeline_row work_package_with_non_working_days.id }

    shared_let(:non_working_day) do
      create(:non_working_day,
             date: '06-01-2021')
    end

    shared_examples "sets dates, duration and displays bar" do
      it 'sets dates, duration and duration bar' do
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

    context 'with an existing duration only' do
      before do
        # Reset dates on each run
        work_package_with_non_working_days.update({ start_date: nil, due_date: nil, duration: 5 })
      end

      it 'displays the hover bar correctly' do
        # Expect no hover bar when hovering over a non working day
        row.hover_bar(offset_days: -1)
        row.expect_no_hovered_bar

        # Expect timeline bar when clicking on a non working day
        row.click_bar(offset_days: -1)
        row.expect_no_bar

        # Expect hovered bar size to equal duration
        row.hover_bar
        row.expect_hovered_bar(duration: work_package_with_non_working_days.duration)

        # Expect hovered bar size to equal duration + non working days
        # when the hovered bar passes through non working days
        row.hover_bar(offset_days: 1)
        row.expect_hovered_bar(duration: work_package_with_non_working_days.duration + 2)
      end

      describe 'set the start, due date while preserving duration' do
        subject { row.click_bar }

        it_behaves_like 'sets dates, duration and displays bar' do
          let(:target_wp) { work_package_with_non_working_days }
          let(:expected_bar_duration) { work_package_with_non_working_days.duration }
          let(:expected_start_date) { Date.parse('2021-01-04') }
          let(:expected_due_date) { Date.parse('2021-01-08') }
          let(:expected_duration) { 4 }
          let(:expected_label) { work_package_with_non_working_days.subject }
        end
      end

      describe 'set the start, due date while preserving duration over the weekend' do
        subject { row.click_bar(offset_days: 1) }

        it_behaves_like 'sets dates, duration and displays bar' do
          let(:target_wp) { work_package_with_non_working_days }
          let(:expected_bar_duration) { work_package_with_non_working_days.duration + 2 }
          let(:expected_start_date) { Date.parse('2021-01-05') }
          let(:expected_due_date) { Date.parse('2021-01-11') }
          let(:expected_duration) { 4 }
          let(:expected_label) { work_package_with_non_working_days.subject }
        end
      end

      describe 'sets the start, due dates while preserving duration on a drag and drop create' do
        subject { row.drag_and_drop(days: 5) }

        it_behaves_like 'sets dates, duration and displays bar' do
          let(:target_wp) { work_package_with_non_working_days }
          let(:expected_bar_duration) { work_package_with_non_working_days.duration }
          let(:expected_start_date) { Date.parse('2021-01-04') }
          let(:expected_due_date) { Date.parse('2021-01-08') }
          let(:expected_duration) { 4 }
          let(:expected_label) { work_package_with_non_working_days.subject }
        end
      end

      describe 'sets the start, due dates while preserving duration on a drag and drop create over the weekend' do
        subject { row.drag_and_drop(offset_days: 1, days: 7) }

        it_behaves_like 'sets dates, duration and displays bar' do
          let(:target_wp) { work_package_with_non_working_days }
          let(:expected_bar_duration) { work_package_with_non_working_days.duration + 2 }
          let(:expected_start_date) { Date.parse('2021-01-05') }
          let(:expected_due_date) { Date.parse('2021-01-11') }
          let(:expected_duration) { 4 }
          let(:expected_label) { work_package_with_non_working_days.subject }
        end
      end

      describe 'sets the start, due dates and duration on a drag and drop create over the weekend' do
        subject { row.drag_and_drop(offset_days: 1, days: 8) }

        it_behaves_like 'sets dates, duration and displays bar' do
          let(:target_wp) { work_package_with_non_working_days }
          let(:expected_bar_duration) { work_package_with_non_working_days.duration + 3 }
          let(:expected_start_date) { Date.parse('2021-01-05') }
          let(:expected_due_date) { Date.parse('2021-01-12') }
          let(:expected_duration) { 5 }
          let(:expected_label) { work_package_with_non_working_days.subject }
        end
      end

      it 'cancels when the drag starts or finishes on a weekend' do
        # Finish on the weekend
        row.drag_and_drop(offset_days: 1, days: 5)

        row.expect_no_bar
        expect { work_package_with_non_working_days.reload }.not_to change { work_package_with_non_working_days }

        # Start on the weekend
        row.drag_and_drop(offset_days: -1, days: 5)

        row.expect_no_bar
        expect { work_package_with_non_working_days.reload }.not_to change { work_package_with_non_working_days }
      end

      context 'when ignore_non_working_days is true' do
        let(:row) { wp_timeline.timeline_row work_package_without_non_working_days.id }

        describe 'sets the start, due dates and duration on a drag and drop create over the weekend' do
          subject { row.drag_and_drop(offset_days: 1, days: 8) }

          it_behaves_like 'sets dates, duration and displays bar' do
            let(:target_wp) { work_package_without_non_working_days }
            let(:expected_bar_duration) { work_package_without_non_working_days.duration + 3 }
            let(:expected_start_date) { Date.parse('2021-01-05') }
            let(:expected_due_date) { Date.parse('2021-01-12') }
            let(:expected_duration) { 8 }
            let(:expected_label) { work_package_without_non_working_days.subject }
          end
        end
      end
    end
  end
end
