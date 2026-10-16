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

module RecurringWorkPackages
  class Series < ApplicationRecord
    MAX_INTERVAL = 100
    MAX_ITERATIONS = 1000

    include Redmine::I18n

    belongs_to :project
    belongs_to :author, class_name: "User"

    has_many :occurrences,
             -> { order(:position) },
             class_name: "RecurringWorkPackages::Occurrence",
             inverse_of: :series,
             dependent: :delete_all
    has_many :work_packages, through: :occurrences

    enum :frequency,
         { daily: 0, working_days: 1, weekly: 2, monthly: 3, yearly: 4 },
         prefix: true,
         default: "weekly"

    enum :end_after,
         { never: 0, specific_date: 1, iterations: 2 },
         prefix: true,
         default: "never"

    validates :start_date, :frequency, :end_after, presence: true
    validates :interval,
              numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_INTERVAL }
    validates :end_date, presence: true, if: :end_after_specific_date?
    validates :iterations,
              numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_ITERATIONS },
              if: :end_after_iterations?
    validate :end_date_after_start_date, if: :end_after_specific_date?

    scope :visible, ->(user = User.current) {
      where(project: Project.allowed_to(user, :view_recurring_work_packages))
    }

    def latest_occurrence
      occurrences.last
    end

    def next_scheduled_date
      latest = latest_occurrence
      return start_date if latest.nil?
      return if end_after_iterations? && latest.position >= iterations

      date = schedule.next_occurrence(latest.scheduled_date.to_time(:utc))&.to_date
      return if date.nil? || (end_after_specific_date? && date > end_date)

      date
    end

    def ended?
      next_scheduled_date.nil?
    end

    def upcoming_dates(limit: 3)
      dates = schedule.next_occurrences(limit, upcoming_from.to_time(:utc)).map(&:to_date)
      dates = dates.select { |date| date <= end_date } if end_after_specific_date?
      end_after_iterations? ? dates.first(remaining_iterations) : dates
    end

    def upcoming_from
      latest_occurrence&.scheduled_date || (start_date - 1.day)
    end

    def remaining_iterations
      [iterations - occurrences.size, 0].max
    end

    def frequency_in_words
      I18n.t("recurring_work_packages.in_words.#{frequency}", count: interval, **schedule_word_parts)
    end

    def occurrence_label(occurrence)
      if end_after_iterations?
        I18n.t("recurring_work_packages.label.of_total",
               schedule: frequency_in_words, position: occurrence.position, total: iterations)
      else
        I18n.t("recurring_work_packages.label.nth", schedule: frequency_in_words, position: occurrence.position)
      end
    end

    def end_in_words
      case end_after
      when "specific_date" then I18n.t("recurring_work_packages.ends.on_date", date: format_date(end_date))
      when "iterations" then I18n.t("recurring_work_packages.ends.after", count: iterations)
      else I18n.t("recurring_work_packages.ends.never")
      end
    end

    def title
      occurrences.first&.work_package&.subject
    end

    def schedule_in_words
      base = frequency_in_words

      case end_after
      when "specific_date"
        I18n.t("recurring_work_packages.in_words.until", base:, date: format_date(end_date))
      when "iterations"
        I18n.t("recurring_work_packages.in_words.times", base:, count: iterations)
      else
        base
      end
    end

    private

    def schedule
      IceCube::Schedule.new(start_date.to_time(:utc)).tap do |s|
        s.add_recurrence_rule(frequency_rule)
      end
    end

    def frequency_rule
      case frequency
      when "daily" then IceCube::Rule.daily(interval)
      when "working_days" then IceCube::Rule.weekly.day(*Setting.working_day_names)
      when "weekly" then IceCube::Rule.weekly(interval)
      when "monthly" then IceCube::Rule.monthly(interval)
      when "yearly" then IceCube::Rule.yearly(interval)
      end
    end

    def schedule_word_parts
      {
        weekday: I18n.l(start_date, format: "%A"),
        day: ordinalize(start_date.day),
        date: I18n.l(start_date, format: "%B %-d")
      }
    end

    def end_date_after_start_date
      return if end_date.blank? || start_date.blank? || end_date >= start_date

      errors.add(:end_date, :greater_than_or_equal_to, count: format_date(start_date))
    end
  end
end
