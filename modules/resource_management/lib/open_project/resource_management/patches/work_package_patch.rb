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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::ResourceManagement::Patches::WorkPackagePatch
  extend ActiveSupport::Concern

  included do
    has_many :visible_allocated_resource_allocations,
             -> { allocated.with_visible_placeholder_or_user },
             class_name: "ResourceAllocation",
             as: :entity
  end

  class_methods do
    def include_allocated_time(work_package_scope)
      sums_table = Arel::Table.new(:allocated_time_sums)
      join = arel_table
               .outer_join(allocated_time_sums(work_package_scope).arel.as(sums_table.name))
               .on(arel_table[:id].eq(sums_table[:entity_id]))

      joins(join.join_sources).select(sums_table[:allocated_minutes])
    end

    private

    def allocated_time_sums(work_package_scope)
      ResourceAllocation
        .allocated
        .where(entity_type: "WorkPackage", entity_id: work_package_scope.select(:id))
        .group(:entity_id)
        .select(:entity_id, "SUM(allocated_time) AS allocated_minutes")
    end
  end

  def allocated_minutes
    if has_attribute?(:allocated_minutes)
      self[:allocated_minutes].to_i
    else
      ResourceAllocation.allocated.where(entity: self).sum(:allocated_time)
    end
  end

  def allocated_principals
    visible_allocated_resource_allocations.map(&:placeholder_or_user).uniq
  end
end
