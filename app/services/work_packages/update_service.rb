#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class WorkPackages::UpdateService
  include ::WorkPackages::Shared::UpdateAncestors
  include ::Shared::ServiceContext

  attr_accessor :user,
                :work_package,
                :contract_class

  def initialize(user:, work_package:, contract_class: WorkPackages::UpdateContract)
    self.user = user
    self.work_package = work_package
    self.contract_class = contract_class
  end

  def call(attributes: {}, send_notifications: true)
    in_context(send_notifications) do
      update(attributes)
    end
  end

  private

  def update(attributes)
    result = set_attributes(attributes)

    if result.success?
      work_package.attachments = work_package.attachments_replacements if work_package.attachments_replacements
      result.merge!(update_dependent)
    end

    if save_if_valid(result)
      update_ancestors([work_package]).each do |ancestor_result|
        result.merge!(ancestor_result)
      end
    end

    result
  end

  def save_if_valid(result)
    if result.success?
      result.success = consolidated_results(result)
                       .all?(&:save)
    end

    result.success?
  end

  def update_dependent
    result = ServiceResult.new(success: true, result: work_package)

    result.merge!(update_descendants)

    cleanup if result.success?

    result.merge!(reschedule_related)

    result
  end

  def set_attributes(attributes, wp = work_package)
    WorkPackages::SetAttributesService
      .new(user: user,
           work_package: wp,
           contract_class: contract_class)
      .call(attributes)
  end

  def update_descendants
    result = ServiceResult.new(success: true, result: work_package)

    if work_package.project_id_changed?
      attributes = { project: work_package.project }

      work_package.descendants.each do |descendant|
        result.add_dependent!(set_attributes(attributes, descendant))
      end
    end

    result
  end

  def cleanup
    if work_package.project_id_changed?
      moved_work_packages = [work_package] + work_package.descendants
      delete_relations(moved_work_packages)
      move_time_entries(moved_work_packages, work_package.project_id)
    end
    if work_package.type_id_changed?
      reset_custom_values
    end
  end

  def delete_relations(work_packages)
    unless Setting.cross_project_work_package_relations?
      Relation
        .non_hierarchy_of_work_package(work_packages)
        .destroy_all
    end
  end

  def move_time_entries(work_packages, project_id)
    TimeEntry
      .on_work_packages(work_packages)
      .update_all(project_id: project_id)
  end

  def reset_custom_values
    work_package.reset_custom_values!
  end

  def reschedule_related
    result = ServiceResult.new(success: true, result: work_package)

    if work_package.parent_id_changed?
      # HACK: we need to persist the parent relation before rescheduling the parent
      # and the former parent
      work_package.send(:update_parent_relation)

      result.merge!(reschedule_former_parent) if work_package.parent_id_was
    end

    result.merge!(reschedule(work_package))

    result
  end

  def reschedule_former_parent
    former_siblings = WorkPackage.includes(:parent_relation).where(relations: { from_id: work_package.parent_id_was })

    reschedule(former_siblings)
  end

  def reschedule(work_packages)
    WorkPackages::SetScheduleService
      .new(user: user,
           work_package: work_packages)
      .call(changed_attributes)
  end

  def changed_attributes
    work_package.changed.map(&:to_sym)
  end

  # When multiple services change a work package, we still only want one update to the database due to:
  # * performance
  # * having only one journal entry
  # * stale object errors
  # we thus consolidate the results so that one instance contains the changes made by all the services.
  def consolidated_results(result)
    result.all_results.group_by(&:id).inject([]) do |a, (_, instances)|
      master = instances.pop

      instances.each do |instance|
        master.attributes = instance.changes.map do |attribute, values|
          [attribute, values.last]
        end.to_h
      end

      a + [master]
    end
  end
end
