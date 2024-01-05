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

class Queries::WorkPackages::Filter::StatusFilter < Queries::WorkPackages::Filter::WorkPackageFilter
  def allowed_values
    all_statuses.values.map { |s| [s.name, s.id.to_s] }
  end

  def available_operators
    [Queries::Operators::OpenWorkPackages,
     Queries::Operators::EqualsOr,
     Queries::Operators::ClosedWorkPackages,
     Queries::Operators::NotEquals,
     Queries::Operators::All]
  end

  def available?
    all_statuses.any?
  end

  def type
    :list
  end

  def self.key
    :status_id
  end

  def value_objects
    values
      .filter_map { |status_id| all_statuses[status_id.to_i] }
  end

  def allowed_objects
    all_statuses.values
  end

  def ar_object_filter?
    true
  end

  def joins
    :status
  end

  private

  def all_statuses
    key = 'Queries::WorkPackages::Filter::StatusFilter/all_statuses'

    RequestStore.fetch(key) do
      Status.all.to_a.index_by(&:id)
    end
  end

  def operator_strategy
    super_value = super

    super_value || case operator
                   when 'o'
                     Queries::Operators::OpenWorkPackages
                   when 'c'
                     Queries::Operators::ClosedWorkPackages
                   when '*'
                     Queries::Operators::All
                   end
  end
end
