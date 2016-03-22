#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class UpdateWorkPackageService
  attr_accessor :user, :work_package

  class << self
    attr_accessor :contract
  end

  self.contract = WorkPackages::UpdateContract

  def initialize(user:, work_package:)
    self.user = user
    self.work_package = work_package

    self.contract = self.class.contract.new(work_package, user)
  end

  def call(attributes: {}, send_notifications: true)
    User.execute_as user do
      JournalManager.with_send_notifications send_notifications do
        update(attributes)
      end
    end
  end

  private

  attr_accessor :contract

  def update(attributes)
    set_attributes(attributes)

    changed_attributes = work_package.changes.dup
    save_result, save_errors = validate_and_save

    if save_result
      cleanup_result, cleanup_errors = cleanup(changed_attributes)

      ServiceResult.new(cleanup_result, cleanup_errors)
    else
      ServiceResult.new(save_result, save_errors)
    end
  end

  def set_attributes(attributes)
    work_package.attributes = attributes
  end

  def validate_and_save
    if !contract.validate
      return false, contract.errors
    elsif !work_package.save
      return false, work_package.errors
    else
      return true, work_package.errors
    end
  end

  def cleanup(attributes)
    result = true
    errors = work_package.errors

    if attributes.include?(:project_id)
      delete_relations
      move_time_entries
      result, errors = move_children
    end
    if attributes.include?(:type_id)
      reset_custom_values
    end

    [result, errors]
  end

  def delete_relations
    unless Setting.cross_project_work_package_relations?
      work_package.relations_from.clear
      work_package.relations_to.clear
    end
  end

  def move_time_entries
    work_package.move_time_entries(work_package.project)
  end

  def reset_custom_values
    work_package.reset_custom_values!
  end

  def move_children
    work_package.children.each do |child|
      result, errors = UpdateChildWorkPackageService
                       .new(user: user,
                            work_package: child)
                       .call(attributes: { project: work_package.project })

      return result, errors unless result
    end

    [true, work_package.errors]
  end
end
