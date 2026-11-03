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
  class UpdateContract < BaseContract
    validate :validate_start_after_preceeding_phases
    validate :validate_start_date_is_a_working_day
    validate :validate_finish_date_is_a_working_day
    validate :validate_date_format

    delegate :project, to: :model

    def writable_attributes = %w[start_date finish_date]

    def validate_start_after_preceeding_phases
      return unless model.active?
      return unless model.date_range_set?
      return if start_after_preceding_phases?

      model.errors.add(:start_date, :non_continuous_dates)
    end

    def validate_start_date_is_a_working_day
      if model.start_date.present? && !model.start_date.in?(working_days)
        model.errors.add(:start_date, :cannot_be_a_non_working_day)
      end
    end

    def validate_finish_date_is_a_working_day
      if model.finish_date.present? && !model.finish_date.in?(working_days)
        model.errors.add(:finish_date, :cannot_be_a_non_working_day)
      end
    end

    def validate_date_format
      %i[start_date finish_date].each do |attr|
        raw_value = model.send("#{attr}_before_type_cast")
        if raw_value.present? && raw_value.is_a?(String) && !raw_value.match?(/^\d{4}-\d{2}-\d{2}$/)
          model.errors.add(attr, :invalid)
        end
      end
    end

    private

    def start_after_preceding_phases?
      preceding_phases
        .select(&:date_range_set?)
        .all? { valid_dates?(current: model, previous: it) }
    end

    def valid_dates?(current:, previous:)
      current.start_date > previous.finish_date
    end

    def preceding_phases
      project.available_phases.select { it.position < model.position }
    end

    def working_days
      return @working_days if defined?(@working_days)

      dates = [model.start_date, model.finish_date].compact
      @working_days = if dates.any?
                        Day.from_range(from: dates.min, to: dates.max).working.pluck("days.date")
                      else
                        []
                      end
    end
  end
end
