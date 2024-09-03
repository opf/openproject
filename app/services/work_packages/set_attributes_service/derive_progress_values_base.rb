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

class WorkPackages::SetAttributesService
  class DeriveProgressValuesBase
    attr_reader :work_package

    def initialize(work_package)
      @work_package = work_package
    end

    def call
      derive_progress_attributes
      round_progress_values
    end

    def work
      work_package.estimated_hours
    end

    def work=(value)
      work_package.estimated_hours = value
    end

    def work_was
      work_package.estimated_hours_was
    end

    def work_set?
      work.present?
    end

    def work_empty?
      work.nil?
    end

    def work_was_empty?
      work_package.estimated_hours_was.nil?
    end

    def work_changed?
      work_package.estimated_hours_changed?
    end

    def work_came_from_user?
      work_package.estimated_hours_came_from_user?
    end

    def work_not_provided_by_user?
      !work_came_from_user?
    end

    def work_valid?
      DurationConverter.valid?(work_package.estimated_hours_before_type_cast)
    end

    def remaining_work
      work_package.remaining_hours
    end

    def remaining_work=(value)
      work_package.remaining_hours = value
    end

    def remaining_work_set?
      remaining_work.present?
    end

    def remaining_work_empty?
      remaining_work.nil?
    end

    def remaining_work_was_empty?
      work_package.remaining_hours_was.nil?
    end

    def remaining_work_changed?
      work_package.remaining_hours_changed?
    end

    def remaining_work_came_from_user?
      work_package.remaining_hours_came_from_user?
    end

    def remaining_work_not_provided_by_user?
      !remaining_work_came_from_user?
    end

    def remaining_work_valid?
      DurationConverter.valid?(work_package.remaining_hours_before_type_cast)
    end

    def percent_complete
      work_package.done_ratio
    end

    def percent_complete=(value)
      work_package.done_ratio = value
    end

    def percent_complete_set?
      percent_complete.present?
    end

    def percent_complete_empty?
      percent_complete.nil?
    end

    def percent_complete_was_empty?
      work_package.done_ratio_was.nil?
    end

    def percent_complete_changed?
      work_package.done_ratio_changed?
    end

    def percent_complete_came_from_user?
      work_package.done_ratio_came_from_user?
    end

    def percent_complete_not_provided_by_user?
      !percent_complete_came_from_user?
    end

    private

    def set_hint(field, hint)
      work_package.derived_progress_hints[field] = hint
    end

    def round_progress_values
      # The values are set only when rounding returns a different value. Doing
      # otherwise would modify the values returned by `xxx_before_type_cast` and
      # prevent the numericality validator from working when setting the field
      # to a string value.
      rounded = work&.round(2)
      if rounded != work && work_valid?
        self.work = rounded
      end
      rounded = remaining_work&.round(2)
      if rounded != remaining_work && remaining_work_valid?
        self.remaining_work = rounded
      end
    end

    def remaining_work_from_percent_complete_and_work
      completed_work = work * percent_complete / 100.0
      remaining_work = (work - completed_work).round(2)
      remaining_work.clamp(0.0, work)
    end
  end
end
