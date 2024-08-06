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

class WorkPackagePolicy < BasePolicy
  private

  def cache(work_package)
    @cache ||= Hash.new do |wp_hash, wp|
      wp_hash[wp] = allowed_hash(wp)
    end

    @cache[work_package]
  end

  def allowed_hash(work_package)
    # copy checks for the move_work_packages permission. This makes
    # sense only because the work_packages/moves controller handles
    # copying multiple work packages.
    {
      edit: edit_allowed?(work_package),
      move: move_allowed?(work_package),
      copy: move_allowed?(work_package),
      duplicate: copy_allowed?(work_package), # duplicating is another form of copying
      delete: delete_allowed?(work_package),
      manage_subtasks: manage_subtasks_allowed?(work_package),
      comment: comment_allowed?(work_package),
      change_status: change_status_allowed?(work_package),
      assign_version: assign_version_allowed?(work_package)
    }
  end

  def edit_allowed?(work_package)
    work_package.persisted? && user.allowed_in_work_package?(:edit_work_packages, work_package)
  end

  def move_allowed?(work_package)
    user.allowed_in_project?(:move_work_packages, work_package.project)
  end

  def copy_allowed?(work_package)
    type_active_in_project?(work_package) && add_allowed?(work_package)
  end

  def delete_allowed?(work_package)
    user.allowed_in_project?(:delete_work_packages, work_package.project)
  end

  def add_allowed?(work_package)
    user.allowed_in_project?(:add_work_packages, work_package.project)
  end

  def type_active_in_project?(work_package)
    return false unless work_package.project

    @type_active_cache ||= Hash.new do |hash, project|
      hash[project] = project.types.pluck(:id)
    end

    @type_active_cache[work_package.project].include?(work_package.type_id)
  end

  def manage_subtasks_allowed?(work_package)
    user.allowed_in_project?(:manage_subtasks, work_package.project)
  end

  def comment_allowed?(work_package)
    user.allowed_in_work_package?(:add_work_package_notes, work_package) || edit_allowed?(work_package)
  end

  def assign_version_allowed?(work_package)
    user.allowed_in_project?(:assign_versions, work_package.project)
  end

  def change_status_allowed?(work_package)
    @change_status_cache ||= Hash.new do |hash, project|
      hash[project] = user.allowed_in_project?(%i[edit_work_packages change_work_package_status], work_package.project)
    end

    @change_status_cache[work_package.project]
  end
end
