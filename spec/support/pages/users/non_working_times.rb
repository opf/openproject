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

require "support/pages/page"

module Pages
  module Users
    class NonWorkingTimes < ::Pages::Page
      attr_reader :user, :year

      # Pass user: nil for the /my/non_working_times context
      def initialize(user: nil, year: Date.current.year)
        super()
        @user = user
        @year = year
      end

      def path
        if user
          edit_user_path(user, tab: :non_working_times, year:)
        else
          my_non_working_times_path(year:)
        end
      end

      def dialog_selector
        "##{::Users::NonWorkingTimes::DialogComponent::DIALOG_ID}"
      end

      # -- Actions --

      def open_create_dialog
        click_on I18n.t(:button_add_non_working_time)
        expect(page).to have_css(dialog_selector)
      end

      def open_edit_dialog_from_sidebar
        find("a[data-controller='async-dialog'][href*='/edit']").click
        expect(page).to have_css(dialog_selector)
      end

      def open_edit_dialog_from_calendar
        find(".non-working-day--user").click
        expect(page).to have_css(dialog_selector)
      end

      def click_calendar_day(date)
        find("[data-date='#{date}']").click
      end

      def set_start_date(date)
        set_date_field(:start_date, date)
      end

      def set_end_date(date)
        set_date_field(:end_date, date)
      end

      def confirm_dialog
        within(dialog_selector) { click_on I18n.t(:button_confirm) }
        expect(page).to have_no_css(dialog_selector)
      end

      def delete_in_dialog
        accept_confirm do
          within(dialog_selector) { click_on I18n.t(:button_delete) }
        end
        expect(page).to have_no_css(dialog_selector)
      end

      # -- Expectations --

      def expect_dialog_open
        expect(page).to have_css(dialog_selector)
      end

      def expect_dialog_closed
        expect(page).to have_no_css(dialog_selector)
      end

      def expect_dialog_start_date(value)
        within(dialog_selector) do
          expect(page).to have_field("user_non_working_time[start_date]", with: value)
        end
      end

      def expect_dialog_end_date(value)
        within(dialog_selector) do
          expect(page).to have_field("user_non_working_time[end_date]", with: value)
        end
      end

      def expect_dialog_dates(start_date:, end_date:)
        expect_dialog_start_date(start_date)
        expect_dialog_end_date(end_date)
      end

      def expect_dialog_has_delete_button
        within(dialog_selector) do
          expect(page).to have_link(I18n.t(:button_delete))
        end
      end

      def expect_validation_error(message)
        within(dialog_selector) do
          expect(page).to have_text(message)
        end
      end

      def expect_working_days_count(count)
        expect(page).to have_field(I18n.t(:label_working_days), with: count.to_s)
      end

      def expect_sidebar_entry(text)
        expect(page).to have_css("a[data-controller='async-dialog']", text:)
      end

      def expect_no_sidebar_entry(text)
        expect(page).to have_no_css("a[data-controller='async-dialog']", text:)
      end

      def expect_add_button
        expect(page).to have_link(I18n.t(:button_add_non_working_time))
      end

      def expect_no_add_button
        expect(page).to have_no_link(I18n.t(:button_add_non_working_time))
      end

      def expect_selectable_calendar
        expect(page).to have_css("[data-users--non-working-times-new-url-value]")
      end

      def expect_non_selectable_calendar
        expect(page).to have_no_css("[data-users--non-working-times-new-url-value]")
      end

      def expect_calendar_rendered
        expect(page).to have_css(".op-fc-wrapper")
        expect(page).to have_css(".users-non-working-times-calendar-view")
      end

      def expect_not_authorized
        expect(page).to have_text(I18n.t(:notice_not_authorized))
      end

      private

      def set_date_field(field_name, date)
        datepicker = Components::BasicDatepicker.new(dialog_selector)
        datepicker.open("input[name='user_non_working_time[#{field_name}]']")
        datepicker.set_date(date)
      end
    end
  end
end
