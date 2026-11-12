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

module ProjectPhases
  class RescheduleService < ::BaseServices::BaseContracted
    alias_method :project, :model

    def initialize(user:, project:, contract_class: nil, contract_options: {})
      super(user:, contract_class:, contract_options:)
      self.model = project
    end

    private

    def persist(service_call)
      reschedule_phases(**params)

      service_call
    end

    def reschedule_phases(phases:, from:)
      phases.each do |phase|
        next unless phase.active?

        next_start_date = if phase.date_range_set?
                            reschedule_phase_and_retrieve_next_start(phase, from)
                          else
                            reschedule_partial_phase_and_retrieve_next_start(phase, from)
                          end

        from = next_start_date unless next_start_date.nil?
      end
    end

    def reschedule_phase_and_retrieve_next_start(phase, from)
      return unless phase.duration&.positive?

      date_range = calculate_date_range(from, duration: phase.duration)
      return unless date_range
      return unless phase.update(start_date: date_range[0], finish_date: date_range[1])

      date_range[1] + 1
    end

    def calculate_date_range(from, duration:)
      days = working_days_from(from, count: duration)

      [days.first, days.last] if days.length == duration
    end

    def reschedule_partial_phase_and_retrieve_next_start(phase, from)
      phase.start_date = calculate_start_date(from)
      next_start_date = phase.start_date

      if phase.finish_date?
        phase.finish_date = calculate_finish_date(phase, from)
        phase.duration = phase.calculate_duration
        # The phase's date range is complete now, and 1 day gap should follow it.
        next_start_date = phase.finish_date + 1
      end

      phase.save

      next_start_date
    end

    def calculate_start_date(from)
      working_days_from(from, count: 1).first
    end

    def calculate_finish_date(phase, from)
      max_finish_date = [from, phase.finish_date].max
      working_days_from(max_finish_date, count: 1).first
    end

    def working_days_from(from, count:)
      days = Day.working.from_range(from:, to: from.next_year).limit(count).pluck(days: :date)
      if days.length < count && !days.empty?
        years = count.ceildiv(days.length) + 1
        days = Day.working.from_range(from:, to: from.next_year(years)).limit(count).pluck(days: :date)
      end
      days
    end

    def default_contract_class
      ProjectPhases::RescheduleContract
    end
  end
end
