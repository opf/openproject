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

class WorkPackages::SetAttributesService
  include Concerns::Contracted

  attr_accessor :user,
                :work_package,
                :contract

  def initialize(user:, work_package:, contract:)
    self.user = user
    self.work_package = work_package

    self.contract = contract.new(work_package, user)
  end

  def call(attributes)
    set_attributes(attributes)

    validate_and_result
  end

  private

  def validate_and_result
    boolean, errors = validate(work_package)

    ServiceResult.new(success: boolean,
                      errors: errors,
                      result: work_package)
  end

  def set_attributes(attributes)
    work_package.attributes = attributes

    set_default_attributes if work_package.new_record?

    unify_dates if work_package_now_milestone?

    update_project_dependent_attributes if work_package.project_id_changed? && work_package.project_id

    # Take over any default custom values
    # for new custom fields
    work_package.set_default_values! if custom_field_context_changed?
  end

  def set_default_attributes
    work_package.priority ||= IssuePriority.active.default
    work_package.author ||= user
    work_package.status ||= Status.default
  end

  def unify_dates
    unified_date = work_package.due_date || work_package.start_date
    work_package.start_date = work_package.due_date = unified_date
  end

  def custom_field_context_changed?
    work_package.type_id_changed? || work_package.project_id_changed?
  end

  def work_package_now_milestone?
    work_package.type_id_changed? && work_package.milestone?
  end

  def update_project_dependent_attributes
    set_fixed_version_to_nil
    reassign_category
    reassign_type unless work_package.type_id_changed?
  end

  def set_fixed_version_to_nil
    unless work_package.fixed_version &&
           work_package.project.shared_versions.include?(work_package.fixed_version)
      work_package.fixed_version = nil
    end
  end

  def reassign_category
    # work_package is moved to another project
    # reassign to the category with same name if any
    if work_package.category.present?
      category = work_package.project.categories.find_by(name: work_package.category.name)

      work_package.category = category
    end
  end

  def reassign_type
    available_types = work_package.project.types.order(:position)

    return if available_types.include?(work_package.type) && work_package.type

    work_package.type = available_types.detect(&:is_default) || available_types.first

    reassign_status
  end

  def reassign_status
    available_statuses = work_package.new_statuses_allowed_to(user, true)

    return if available_statuses.include? work_package.status

    work_package.status = available_statuses.detect(&:is_default) || available_statuses.first
  end
end
