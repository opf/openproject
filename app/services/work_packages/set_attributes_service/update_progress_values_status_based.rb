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
  class UpdateProgressValuesStatusBased < UpdateProgressValuesBase
    private

    def update_progress_attributes
      raise ArgumentError, "Cannot use self.class.name for work-based mode" if WorkPackage.use_field_for_done_ratio?

      update_done_ratio
      update_remaining_hours_from_percent_complete
    end

    # Update +done_ratio+ from the status if the status changed.
    def update_done_ratio
      return unless work_package.status_id_changed?

      work_package.done_ratio = work_package.status.default_done_ratio
    end

    # When in "Status-based" mode for % Complete, remaining hours are based
    # on the computation of it derived from the status's default done ratio
    # and the estimated hours. If the estimated hours are unset, then also
    # unset the remaining hours.
    def update_remaining_hours_from_percent_complete
      return if work_package.remaining_hours_came_from_user?
      return if work_package.estimated_hours&.negative?

      work_package.remaining_hours = remaining_hours_from_done_ratio_and_estimated_hours
    end
  end
end
