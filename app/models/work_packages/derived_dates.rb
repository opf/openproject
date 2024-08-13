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

module WorkPackages::DerivedDates
  # Returns the maximum of the dates of all descendants (start and due date)
  # No visibility check is applied so a user will always see the maximum regardless of his permission.
  #
  # The value can stem from either eager loading the value via
  # WorkPackage.include_derived_dates in which case the work package has a
  # derived_start_date attribute or it is loaded on calling the method.
  def derived_start_date
    derived_date("derived_start_date")
  end

  # Returns the minimum of the dates of all descendants (start and due date)
  # No visibility check is applied so a user will always see the minimum regardless of his permission.
  #
  # The value can stem from either eager loading the value via
  # WorkPackage.include_derived_dates in which case the work package has a
  # derived_due_date attribute or it is loaded on calling the method.
  def derived_due_date
    derived_date("derived_due_date")
  end

  def derived_start_date=(date)
    compute_derived_dates
    @derived_dates[0] = date
  end

  def derived_due_date=(date)
    compute_derived_dates
    @derived_dates[1] = date
  end

  def reload(*)
    @derived_dates = nil
    super
  end

  private

  def derived_date(key)
    if attributes.key?(key)
      attributes[key]
    else
      compute_derived_dates[key]
    end
  end

  def compute_derived_dates
    @derived_dates ||= begin
      attributes = %w[derived_start_date derived_due_date]

      values = if persisted?
                 WorkPackage
                   .from(WorkPackage.include_derived_dates.where(id: self))
                   .pick(*attributes.each { |a| Arel.sql(a) }) || []
               else
                 []
               end

      attributes
        .zip(values)
        .to_h
    end
  end
end
