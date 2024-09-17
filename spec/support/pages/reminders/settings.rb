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
  module Reminders
    class Settings < ::Pages::Page
      attr_reader :user

      def initialize(user)
        super()
        @user = user
      end

      def path
        edit_user_path(user, tab: :reminders)
      end

      def add_time
        click_button "Add time"
      end

      def set_time(label, time)
        select time, from: label
      end

      def deactivate_time(label)
        find("[data-test-selector='op-settings-daily-time--active-#{label.split[1]}']").click
      end

      def remove_time(label)
        find("[data-test-selector='op-settings-daily-time--remove-#{label.split[1]}']").click
      end

      def expect_active_daily_times(*times)
        times.each_with_index do |time, index|
          expect(page)
            .to have_css("input[data-test-selector='op-settings-daily-time--active-#{index + 1}']:checked")

          expect(page)
            .to have_field("Time #{index + 1}", text: time)
        end
      end

      def expect_immediate_reminder(name, enabled)
        if enabled
          expect(page).to have_css("input[data-qa-immediate-reminder='#{name}']:checked")
        else
          expect(page).to have_css("input[data-qa-immediate-reminder='#{name}']:not(:checked)")
        end
      end

      def set_immediate_reminder(name, enabled)
        field = page.find("input[data-qa-immediate-reminder='#{name}']")

        if enabled
          field.check
        else
          field.uncheck
        end
      end

      def expect_workdays(days)
        days.each do |name|
          expect(page).to have_checked_field(name)
        end
      end

      def expect_non_workdays(days)
        days.each do |name|
          expect(page).to have_unchecked_field(name)
        end
      end

      def set_workdays(days)
        days.each do |name, enabled|
          if enabled
            page.check name
          else
            page.uncheck name
          end
        end
      end

      def expect_paused(paused, first: nil, last: nil)
        if paused
          expect(page).to have_checked_field "Temporarily pause daily email reminders"
        else
          expect(page).to have_no_checked_field "Temporarily pause daily email reminders"
        end

        if first && last
          expect(page).to have_css('[data-test-selector="op-basic-range-date-picker"]',
                                   value: "#{first.iso8601} - #{last.iso8601}")
        end
      end

      def set_paused(paused, first: nil, last: nil)
        if paused
          check "Temporarily pause daily email reminders"

          page.find("op-basic-range-date-picker input").click

          datepicker = ::Components::RangeDatepicker.new
          datepicker.set_date first
          datepicker.set_date last
        else
          uncheck "Temporarily pause daily email reminders"
        end
      end

      def save
        click_button I18n.t("js.button_save")
      end
    end
  end
end
