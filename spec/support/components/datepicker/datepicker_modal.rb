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

module Components
  class DatepickerModal < Datepicker
    def open_modal!
      click_on "Non-working day"
      expect_visible
    end

    def set_date_input(date)
      retry_block do
        set_date(date)
        input = find_field("date")
        raise "Expected date to equal #{date}, but got #{input.value}" unless input.value == date.iso8601
      end
    end

    def has_day_selected?(value)
      flatpickr_container.has_css?(".flatpickr-day.selected", text: value, wait: 1)
    end

    ##
    # Select month from datepicker
    def select_month(month)
      month = Date::MONTHNAMES.index(month) if month.is_a?(String)
      retry_block do
        current_month = current_month_index

        if current_month < month
          month_difference = month - current_month
          month_difference.times { flatpickr_container.find(".flatpickr-next-month").click }
        elsif current_month > month
          month_difference = current_month - month
          month_difference.times { flatpickr_container.find(".flatpickr-prev-month").click }
        end
        current_month_index
      end
    end

    # Returns the index of the current month.
    #
    # 1 for January, 2 for February, etc.
    #
    # When multiple months are displayed, it returns the value for the first one
    # displayed.
    def current_month_index
      # ensure flatpicker month is displayed
      flatpickr_container.first(".flatpickr-month")

      # Checking if showing multiple months or using `monthSelectorType: "static"`,
      # in which case the month is simply some static text in a span instead of a
      # `<select>` dropdown input.
      if flatpickr_container.all(".cur-month", wait: 0).any?
        # Get value from month name and convert to index
        current_month_element = flatpickr_container.first(".cur-month")
        Date::MONTHNAMES.index(current_month_element.text)
      else
        # get value from select dropdown value
        flatpickr_container.first(".flatpickr-monthDropdown-months").value.to_i + 1
      end
    end
  end
end
