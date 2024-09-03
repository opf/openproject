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
  class DeriveProgressValuesStatusBased < DeriveProgressValuesBase
    private

    def derive_progress_attributes
      raise ArgumentError, "Cannot use #{self.class.name} in work-based mode" if WorkPackage.work_based_mode?

      update_percent_complete
      update_remaining_work_from_percent_complete
    end

    # Update +% complete+ from the status if the status changed.
    def update_percent_complete
      return unless work_package.status_id_changed?

      self.percent_complete = work_package.status.default_done_ratio
    end

    # When in "Status-based" mode for progress calculation, remaining work is
    # always derived from % complete and work. If work is unset, then remaining
    # work must be unset too.
    def update_remaining_work_from_percent_complete
      return if remaining_work_came_from_user?
      return if work&.negative?

      if work_empty?
        return unless work_changed?

        set_hint(:remaining_hours, :cleared_because_work_is_empty)
        self.remaining_work = nil
      else
        set_hint(:remaining_hours, :derived)
        self.remaining_work = remaining_work_from_percent_complete_and_work
      end
    end
  end
end
