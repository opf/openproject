#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
  class UpdateProgressValuesBase
    attr_reader :work_package

    def initialize(work_package)
      @work_package = work_package
    end

    def call
      update_progress_attributes
      round_progress_values
    end

    def work
      work_package.estimated_hours
    end

    def remaining_work
      work_package.remaining_hours
    end

    def percent_complete
      work_package.done_ratio
    end

    def work_unset?
      work.nil?
    end

    def remaining_work_unset?
      remaining_work.nil?
    end

    def percent_complete_unset?
      percent_complete.nil?
    end

    private

    def round_progress_values
      rounded = work&.round(2)
      if rounded != work
        work_package.estimated_hours = rounded
      end
      rounded = remaining_work&.round(2)
      if rounded != remaining_work
        work_package.remaining_hours = rounded
      end
    end

    def remaining_hours_from_done_ratio_and_estimated_hours
      return nil if work_unset? || percent_complete_unset?

      completed_work = work * percent_complete / 100.0
      remaining_hours = (work - completed_work).round(2)
      remaining_hours.clamp(0.0, work)
    end
  end
end
