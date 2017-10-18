#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkPackages::UpdateService
  include ::WorkPackages::Shared::UpdateAncestors
  include ::Shared::ServiceContext

  attr_accessor :user,
                :work_package,
                :contract

  def initialize(user:, work_package:, contract: WorkPackages::UpdateContract)
    self.user = user
    self.work_package = work_package
    self.contract = contract
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
      result.merge!(update_dependent(attributes))
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
      result.success = result.all_results.all?(&:save)
    end

    result.success?
  end

  def update_dependent(attributes)
    result = ServiceResult.new(success: true, result: work_package)

    result.merge!(update_descendants)

    cleanup(attributes) if result.success?

    result.merge!(reschedule_related)

    result
  end

  def set_attributes(attributes, wp = work_package)
    WorkPackages::SetAttributesService
      .new(user: user,
           work_package: wp,
           contract: contract)
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

  def cleanup(attributes)
    project_id = attributes[:project_id] || (attributes[:project] && attributes[:project].id)

    if project_id
      moved_work_packages = [work_package] + work_package.descendants
      delete_relations(moved_work_packages)
      move_time_entries(moved_work_packages, project_id)
    end
    if attributes.include?(:type_id) || attributes.include?(:type)
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
    WorkPackages::SetScheduleService
      .new(user: user,
           work_package: work_package)
      .call(work_package.changed.map(&:to_sym))
  end

  def call_and_assign(method, params, updated, errors)
    send(method, *params).tap do |updated_by_method, errors_by_method|
      errors += errors_by_method
      updated += updated_by_method
    end
  end
end
