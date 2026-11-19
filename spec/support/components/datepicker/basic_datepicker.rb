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

require_relative "datepicker"

module Components
  class BasicDatepicker < Datepicker
    ##
    # Open a datepicker drop field with the trigger,
    # and set the date to the given date.
    # @param trigger [String] Selector to click the trigger at
    # @param date [Date | String] Date or ISO8601 date string to set to
    def self.update_field(trigger, date)
      datepicker = new

      datepicker.instance_eval do
        input = page.find(trigger)
        input.click
      end

      date = Date.parse(date) unless date.is_a?(Date)
      datepicker.set_date(date.strftime("%Y-%m-%d"))
    end

    def flatpickr_container
      container.find(".flatpickr-calendar")
    end

    def open(trigger)
      input = page.find(trigger)
      input.click
    end
  end
end
