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

class UserNonWorkingTime < ApplicationRecord
  ClippedNonWorkingTime = Data.define(
    :non_working_time,
    :start_date,
    :end_date,
    :working_days_count,
    :continues_from_previous_year,
    :continues_into_next_year
  ) do
    delegate :id, :user, :user_id, to: :non_working_time
  end
  belongs_to :user, inverse_of: :non_working_times

  validates :start_date, :end_date, presence: true
  validate :end_date_not_before_start_date
  validate :no_overlapping_ranges

  # Returns records whose range overlaps the given inclusive date range.
  scope :overlapping, ->(date_range) {
    where("daterange(start_date, end_date, '[]') && daterange(?, ?, '[]')",
          date_range.begin, date_range.end)
  }

  # Returns records whose range overlaps with the given year.
  scope :for_year, ->(year) { overlapping(Date.new(year, 1, 1)..Date.new(year, 12, 31)) }

  scope :for_user, ->(user) { where(user:) }

  scope :visible, ->(user = User.current) do
    if user.allowed_globally?(:manage_working_times)
      all
    else
      where(user:)
    end
  end

  def days
    start_date..end_date
  end

  def calendar_days_count
    (end_date - start_date).to_i + 1
  end

  def working_days
    return [] if start_date.blank? || end_date.blank?

    working_days_in(days)
  end

  delegate :count, to: :working_days, prefix: true

  def clip_to_year(year, system_non_working_dates: nil)
    year_start = Date.new(year, 1, 1)
    year_end   = Date.new(year, 12, 31)

    clipped_start = [start_date, year_start].max
    clipped_end   = [end_date,   year_end].min

    ClippedNonWorkingTime.new(
      non_working_time: self,
      start_date: clipped_start,
      end_date: clipped_end,
      working_days_count: working_days_in(clipped_start..clipped_end, system_non_working_dates:).count,
      continues_from_previous_year: start_date < year_start,
      continues_into_next_year: end_date > year_end
    )
  end

  private

  def working_days_in(date_range, system_non_working_dates: nil)
    working_wdays = Setting.working_days.map { |d| d % 7 }
    system_wide = system_non_working_dates || NonWorkingDay.for_dates(date_range).pluck(:date).to_set
    date_range.select { |date| working_wdays.include?(date.wday) && system_wide.exclude?(date) }
  end

  def end_date_not_before_start_date
    return unless start_date.present? && end_date.present?

    errors.add(:end_date, :not_before_start_date) if end_date < start_date
  end

  def no_overlapping_ranges
    return unless start_date.present? && end_date.present? && user_id.present?
    return if end_date < start_date

    errors.add(:start_date, :overlapping_range) if overlapping_range_exists?
  end

  def overlapping_range_exists?
    scope = self.class.where(user_id:).overlapping(start_date..end_date)
    scope = scope.where.not(id:) if persisted?
    scope.exists?
  end
end
