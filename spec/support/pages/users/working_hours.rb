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
    class WorkingHours < ::Pages::Page
      attr_reader :user

      # Pass user: nil for the /my/working_hours context
      def initialize(user: nil)
        super()
        @user = user
      end

      def path
        if user
          edit_user_path(user, tab: :working_hours)
        else
          my_working_hours_path
        end
      end

      def dialog_selector
        "##{::Users::WorkingHours::DialogComponent::DIALOG_ID}"
      end

      # -- Actions --

      def open_current_schedule_dialog
        find("a[data-controller='async-dialog'][href*='current']").click
        expect(page).to have_css(dialog_selector)
      end

      def open_add_future_schedule_dialog
        first("a[data-controller='async-dialog'][href$='working_hours/new']").click
        expect(page).to have_css(dialog_selector)
      end

      def open_row_action_menu
        find(:link_or_button) { it.has_selector?("svg.octicon-kebab-horizontal") }.click
      end

      def set_valid_from(date)
        datepicker = Components::BasicDatepicker.new(dialog_selector)
        datepicker.open("input[name='user_working_hours[valid_from]']")
        datepicker.set_date(date)
      end

      def set_availability_factor(value)
        within(dialog_selector) do
          fill_in "user_working_hours[availability_factor]", with: value.to_s
        end
      end

      def submit_dialog
        within(dialog_selector) { click_on I18n.t(:button_create) }
        expect(page).to have_no_css(dialog_selector)
      end

      def save_dialog
        within(dialog_selector) { click_on I18n.t(:button_save) }
        expect(page).to have_no_css(dialog_selector)
      end

      def delete_schedule
        accept_confirm do
          click_on I18n.t(:button_delete)
        end
        expect(page).to have_no_css(dialog_selector)
      end

      # -- Expectations --

      def expect_current_schedule_section
        expect(page).to have_text(I18n.t("users.working_hours.current_schedule.title"))
      end

      def expect_future_section
        expect(page).to have_text(I18n.t("users.working_hours.future.title"))
      end

      def expect_history_section
        expect(page).to have_text(I18n.t("users.working_hours.history.title"))
      end

      def expect_not_set
        expect(page).to have_text(I18n.t("users.working_hours.current_schedule.not_set"), minimum: 1)
      end

      def expect_stats(work_days: nil, weekly_hours: nil, availability: nil, effective_hours: nil)
        expect(page).to have_text(work_days.to_s) if work_days
        expect(page).to have_text(weekly_hours) if weekly_hours
        expect(page).to have_text(availability) if availability
        expect(page).to have_text(effective_hours) if effective_hours
      end

      def expect_future_blank_slate
        expect(page).to have_text(I18n.t("users.working_hours.future.blank_title"))
      end

      def expect_editable_current_schedule
        expect(page).to have_css("a[data-controller='async-dialog'][href*='current']")
      end

      def expect_not_editable_current_schedule
        expect(page).to have_no_css("a[data-controller='async-dialog'][href*='current']")
      end

      def expect_add_future_button
        expect(page).to have_css("a[data-controller='async-dialog'][href$='working_hours/new']")
      end

      def expect_dialog_title_current
        within(dialog_selector) do
          expect(page).to have_text(I18n.t("users.working_hours.form.title_current"))
        end
      end

      def expect_dialog_title_future
        within(dialog_selector) do
          expect(page).to have_text(I18n.t("users.working_hours.form.title"))
        end
      end

      def expect_no_valid_from_field
        within(dialog_selector) do
          expect(page).to have_no_field(I18n.t("users.working_hours.form.start_date"))
        end
      end

      def expect_valid_from_field
        within(dialog_selector) do
          expect(page).to have_field(I18n.t("users.working_hours.form.start_date"))
        end
      end

      def expect_not_authorized
        expect(page).to have_text(I18n.t(:notice_not_authorized))
      end
    end
  end
end
