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

class WorkPackages::DeleteService < BaseServices::Delete
  include ::WorkPackages::Shared::UpdateAncestors

  private

  def persist(service_result)
    # `to_a` is used to avoid lazy loading. If the relation is laded after the
    # work package is deleted, it would return an empty array.
    descendants = model.descendants.to_a
    descendants_check = validate_descendant_deletions(descendants)
    return descendants_check if descendants_check.failure?

    successors = find_successors_of_self_and_descendants(model).to_a

    result = super

    if result.success?
      destroy_descendants(descendants, result)
      update_ancestors_and_successors(successors, result)
      delete_associated_notifications(model)
    end

    result
  end

  def validate_descendant_deletions(descendants)
    descendants.each do |descendant|
      success, errors = validate(descendant, user, options: contract_options)
      next if success

      return ServiceResult.failure(result: model, errors:)
    end

    ServiceResult.success(result: model)
  end

  def destroy_descendants(descendants, result)
    descendants.each do |descendant|
      success = destroy(descendant.reload)
      result.add_dependent!(ServiceResult.new(success:, result: descendant))
    end
  end

  def destroy(work_package)
    work_package.destroy
  rescue ActiveRecord::StaleObjectError
    destroy(work_package.reload)
  end

  def find_successors_of_self_and_descendants(work_package)
    WorkPackage.where(id: Relation.follows.of_predecessor(work_package.self_and_descendants).select(:from_id))
               .where.not(id: work_package.self_and_descendants)
  end

  def update_ancestors_and_successors(successors, result)
    deleted_work_package = result.result

    # There is an issue there: the parent can be saved twice: once for the
    # rescheduling and once for the ancestor update. Ideally, it should be
    # saved only once.
    result.merge!(reschedule_related(deleted_work_package, successors))
    result.merge!(update_ancestors(deleted_work_package))
  end

  def reschedule_related(deleted_work_package, successors)
    work_packages_to_reschedule = Array(deleted_work_package)

    # if parent changed, the former parent needs to be rescheduled too.
    if deleted_work_package.parent_id
      work_packages_to_reschedule << deleted_work_package.parent
    end

    work_packages_to_reschedule += successors

    result = WorkPackages::SetScheduleService
      .new(user:, work_package: work_packages_to_reschedule)
      .call

    result.dependent_results.map(&:result).each do |rescheduled_work_package|
      rescheduled_work_package.save(validate: false)
    end

    result
  end

  def parent_just_changed?(work_package)
    work_package.saved_change_to_parent_id? && work_package.parent_id_before_last_save
  end

  def delete_associated_notifications(model)
    Notification
      .where(resource_type: :WorkPackage, resource_id: model.id)
      .delete_all
  end
end
