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

module WorkPackages::ResourceAllocations
  extend ActiveSupport::Concern

  included do
    has_many :resource_allocations,
             as: :entity,
             dependent: :destroy,
             inverse_of: :entity

    has_many :allocated_resource_allocations,
             -> { allocated },
             class_name: "ResourceAllocation",
             as: :entity,
             dependent: nil,
             inverse_of: :entity

    associated_to_ask_before_destruction ResourceAllocation,
                                         ->(work_packages) { ResourceAllocation.on_work_packages(work_packages).exists? },
                                         method(:cleanup_resource_allocations_before_destruction_of)
  end

  class_methods do
    def include_allocated_time(work_package_scope)
      sums_table = Arel::Table.new(:allocated_time_sums)
      join = arel_table
               .outer_join(allocated_time_sums(work_package_scope).arel.as(sums_table.name))
               .on(arel_table[:id].eq(sums_table[:entity_id]))

      joins(join.join_sources).select(sums_table[:allocated_minutes])
    end

    protected

    # An allocation cannot exist without a work package, so it is either deleted with its
    # work package or moved to another one.
    # Returns whether the deletion may go ahead, as WorkPackage::AskBeforeDestruction expects.
    def cleanup_resource_allocations_before_destruction_of(work_packages, user, to_do = { action: "destroy" }) # rubocop:disable Naming/PredicateMethod
      work_packages = Array(work_packages)

      return false if to_do.blank?

      case to_do[:action]
      when "destroy"
        true
      when "nullify"
        add_resource_allocation_error(work_packages, :nullify_is_not_valid_for_resource_allocations)
        false
      when "reassign"
        reassign_resource_allocations(work_packages, user, to_do[:reassign_to_id]).all?(&:success?)
      else
        false
      end
    end

    private

    def reassign_resource_allocations(work_packages, user, target_id)
      target = resource_allocations_reassign_target(user, target_id)

      if target.nil?
        add_resource_allocation_error(work_packages, :is_not_a_valid_target_for_resource_allocations, id: target_id)
        return [ServiceResult.failure]
      end

      ResourceAllocation.on_work_packages(work_packages).map do |allocation|
        reassign_resource_allocation(allocation, target, user).tap do |call|
          call.errors.full_messages.each { |message| add_resource_allocation_error(work_packages, message) }
        end
      end
    end

    def reassign_resource_allocation(allocation, target, user)
      ResourceAllocations::UpdateService
        .new(user:, model: allocation, contract_class: ResourceAllocations::ReassignContract)
        .call(entity: target)
    end

    def resource_allocations_reassign_target(user, id)
      ::WorkPackage
        .joins(:project)
        .merge(Project.allowed_to(user, :allocate_user_resources))
        .find_by(id:)
    end

    def add_resource_allocation_error(work_packages, key, **)
      work_packages.each { |work_package| work_package.errors.add(:base, key, **) }
    end

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
    allocated_resources.compact.uniq
  end

  def undisclosed_allocated_principals?
    allocated_resources.include?(nil)
  end

  private

  # Hidden users resolve to nil, as `visible_principal` only loads principals
  # visible to the current user.
  def allocated_resources
    allocated_resource_allocations.map do |allocation|
      allocation.principal_id ? allocation.visible_principal : allocation.placeholder_user
    end
  end
end
