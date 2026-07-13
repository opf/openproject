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

class UserWorkingHours < ApplicationRecord
  DAYS = %i[monday tuesday wednesday thursday friday saturday sunday].freeze
  # Maps each day symbol to the Rails I18n date.abbr_day_names index (Sunday = 0)
  DAY_ABBR_INDEX = { monday: 1, tuesday: 2, wednesday: 3, thursday: 4, friday: 5, saturday: 6, sunday: 0 }.freeze

  belongs_to :user, inverse_of: :working_hours

  validates :valid_from, presence: true, uniqueness: { scope: :user_id }
  validates :monday_hours, :tuesday_hours, :wednesday_hours, :thursday_hours, :friday_hours, :saturday_hours, :sunday_hours,
            presence: true,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 24 }
  validates :availability_factor,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  validate :at_least_one_working_day_selected

  scope :for_user, ->(user) { where(user:) }

  scope :past, ->(date = Date.current) { where(valid_from: ..date).order(valid_from: :desc) }
  scope :upcoming, ->(date = Date.current) { where(valid_from: date..).order(valid_from: :asc) }

  scope :history_for, ->(current_record) { where(valid_from: ..current_record.valid_from).order(valid_from: :desc) }

  def self.valid_for_date(date)
    where(valid_from: ..date).order(valid_from: :desc).first
  end

  def self.current
    valid_for_date(Date.current)
  end

  scope :visible, ->(user = User.current) do
    if user.allowed_globally?(:manage_working_times)
      all
    else
      where(user:)
    end
  end

  DAYS.each do |day|
    define_method("#{day}_hours") do
      (public_send(day) / 60.0).round(2)
    end

    define_method("#{day}_hours=") do |value|
      hours = value.is_a?(String) ? (value.to_hours || value) : value
      public_send("#{day}=", (hours.to_f * 60).round)
    end
  end

  def weekly_working_hours
    DAYS.sum { |day| public_send("#{day}_hours") }
  end

  def effective_weekly_working_hours
    ((weekly_working_hours * availability_factor) / 100.0).round(2)
  end

  # Returns the ranges of working days without hours, e.g. "Mon-Fri" or "Mon-Tue, Thu-Fri".
  # Days are grouped by whether they are working days (minutes > 0), ignoring hour differences.
  def working_day_ranges
    DAYS
      .map { |day| [day, public_send(day)] }
      .chunk_while { |(_, m1), (_, m2)| m1.positive? == m2.positive? }
      .select { |group| group.first.last.positive? }
      .map { |group| format_day_range(group) }
      .join(", ")
  end

  # Returns a human-readable summary of working days grouped by consecutive days
  # with the same hours, e.g. "Mon-Thu 8h, Fri 6h" or "Mon-Tue 8h, Thu-Fri 8h".
  def working_days_summary
    DAYS
      .map { |day| [day, public_send("#{day}_hours")] }
      .chunk_while { |(_, h1), (_, h2)| h1 == h2 }
      .reject { |group| group.first.last.zero? }
      .map { |group| format_day_group(group) }
      .join(", ")
  end

  private

  def format_day_range(group)
    first_day = group.first.first
    last_day = group.last.first

    if group.length == 1
      full_day_name(first_day)
    else
      "#{full_day_name(first_day)}-#{full_day_name(last_day)}"
    end
  end

  def format_day_group(group)
    first_day = group.first.first
    last_day = group.last.first
    _, hours = group.first
    range = group.length == 1 ? abbr_day_name(first_day) : "#{abbr_day_name(first_day)}-#{abbr_day_name(last_day)}"
    "#{range} #{format_hours_str(hours)}"
  end

  def format_hours_str(hours)
    rounded = hours.round(2)
    return "#{rounded.to_i}h" if rounded == rounded.to_i

    separator = I18n.t("number.format.separator")
    "#{rounded.to_s.sub('.', separator)}h"
  end

  def full_day_name(day)
    I18n.t("date.day_names")[DAY_ABBR_INDEX[day]]
  end

  def abbr_day_name(day)
    I18n.t("date.abbr_day_names")[DAY_ABBR_INDEX[day]]
  end

  def at_least_one_working_day_selected
    if DAYS.all? { |day| public_send(day).zero? }
      errors.add(:days, :no_working_day)
    end
  end
end
