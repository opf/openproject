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

module WorkPackages::SpentTime
  # Returns the total number of hours spent on this work package and its descendants.
  # The result can be a subset of the actual spent time in cases where the user's permissions
  # are limited, i.e. he lacks the view_time_entries and/or view_work_packages permission.
  #
  # Example:
  #   spent_hours => 0.0
  #   spent_hours => 50.2
  #
  #   The value can stem from either eager loading the value via
  #   WorkPackage.include_spent_time in which case the work package has an
  #   #hours attribute or it is loaded on calling the method.
  def spent_hours(user = User.current)
    if respond_to?(:hours)
      hours.to_f
    else
      compute_spent_hours(user)
    end || 0.0
  end

  private

  def compute_spent_hours(user)
    WorkPackage.include_spent_time(user, self)
      .pluck(Arel.sql('SUM(hours)'))
      .first
  end
end
