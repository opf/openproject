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

class WorkPackages::UpdateService < BaseServices::Update
  include ::WorkPackages::Shared::UpdateAncestors
  include Attachments::ReplaceAttachments

  attr_accessor :cause_of_rescheduling

  def initialize(user:, model:, contract_class: nil, contract_options: {}, cause_of_rescheduling: nil)
    super(user:, model:, contract_class:, contract_options:)
    self.cause_of_rescheduling = cause_of_rescheduling || model
  end

  private

  def after_perform(service_call)
    update_related_work_packages(service_call)
    cleanup(service_call.result)

    service_call
  end

  def update_related_work_packages(service_call)
    update_ancestors([service_call.result]).each do |ancestor_service_call|
      ancestor_service_call.dependent_results.each do |ancestor_dependent_service_call|
        service_call.add_dependent!(ancestor_dependent_service_call)
      end
    end

    update_related(service_call.result).each do |related_service_call|
      service_call.add_dependent!(related_service_call)
    end
  end

  def update_related(work_package)
    consolidated_calls(update_descendants(work_package) + reschedule_related(work_package))
      .each { |dependent_call| dependent_call.result.save(validate: false) }
  end

  def update_descendants(work_package)
    if work_package.saved_change_to_project_id?
      attributes = { project: work_package.project }

      work_package.descendants.map do |descendant|
        set_descendant_attributes(attributes, descendant)
      end
    else
      []
    end
  end

  def set_descendant_attributes(attributes, descendant)
    WorkPackages::SetAttributesService
      .new(user:,
           model: descendant,
           contract_class: WorkPackages::UpdateDependentContract)
      .call(attributes)
  end

  def cleanup(work_package)
    if work_package.saved_change_to_project_id?
      moved_work_packages = [work_package] + work_package.descendants
      delete_relations(moved_work_packages)
      move_time_entries(moved_work_packages, work_package.project_id)
      move_work_package_memberships(moved_work_packages, work_package.project_id)
    end
    if work_package.saved_change_to_type_id?
      reset_custom_values(work_package)
    end
  end

  def delete_relations(work_packages)
    unless Setting.cross_project_work_package_relations?
      Relation
        .of_work_package(work_packages)
        .destroy_all
    end
  end

  def move_time_entries(work_packages, project_id)
    TimeEntry
      .on_work_packages(work_packages)
      .update_all(project_id:)
  end

  def move_work_package_memberships(work_packages, project_id)
    Member
      .where(entity: work_packages)
      .update_all(project_id:)
  end

  def reset_custom_values(work_package)
    work_package.reset_custom_values!
  end

  def reschedule_related(work_package)
    rescheduled = if work_package.saved_change_to_parent_id? && work_package.parent_id_before_last_save
                    reschedule_former_siblings(work_package).dependent_results
                  else
                    []
                  end

    rescheduled + reschedule(work_package, [work_package]).dependent_results
  end

  def reschedule_former_siblings(work_package)
    reschedule(work_package, WorkPackage.where(parent_id: work_package.parent_id_before_last_save))
  end

  def reschedule(work_package, work_packages)
    WorkPackages::SetScheduleService
      .new(user:, work_package: work_packages, initiated_by: cause_of_rescheduling)
      .call(work_package.saved_changes.keys.map(&:to_sym))
  end

  # When multiple services change a work package, we still only want one update to the database due to:
  # * performance
  # * having only one journal entry
  # * stale object errors
  # we thus consolidate the results so that one instance contains the changes made by all the services.
  def consolidated_calls(service_calls)
    service_calls
      .group_by { |sc| sc.result.id }
      .map do |(_, same_work_package_calls)|
      same_work_package_calls.pop.tap do |master|
        same_work_package_calls.each do |sc|
          master.result.attributes = sc.result.changes.transform_values(&:last)
        end
      end
    end
  end
end
