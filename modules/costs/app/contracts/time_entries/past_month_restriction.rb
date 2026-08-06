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

module TimeEntries
  module PastMonthRestriction
    extend ActiveSupport::Concern

    included do
      validate :validate_spent_on_not_in_past_month
    end

    private

    def validate_spent_on_not_in_past_month
      return unless TimeEntry.prohibit_logging_for_past_months?
      return unless restricted_spent_on_dates.any? { it < earliest_open_date }

      errors.add :spent_on, :in_past_month, date: I18n.l(earliest_open_date)
    end

    # The persisted date is checked alongside the assigned one, so that an entry belonging
    # to a closed month cannot be pulled out of it by moving it into an open one.
    def restricted_spent_on_dates
      [model.spent_on, model.spent_on_was].compact
    end

    # Months are closed as a whole, so the grace period opens every month that the date
    # it reaches back to belongs to. Without grace this is the start of the current month.
    def earliest_open_date
      (Time.zone.today - TimeEntry.past_month_grace_days).beginning_of_month
    end
  end
end
