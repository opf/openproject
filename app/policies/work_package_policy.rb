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

# This capsulates permissions a user has for a work package.  It caches based
# on the work package's project and is thus optimized for the context menu.
#
# This is no conern but it was placed here so that it will be removed together
# with the rest of the experimental API.

class WorkPackagePolicy < BasePolicy
  private

  def cache(work_package)
    @cache ||= Hash.new do |wp_hash, wp|
      wp_hash[wp] = Hash.new do |project_hash, project|
        project_hash[project] = allowed_hash(wp)
      end
    end

    @cache[work_package][work_package.project]
  end

  def allowed_hash(work_package)
    # copy checks for the move_work_packages permission. This makes
    # sense only because the work_packages/moves controller handles
    # copying multiple work packages.
    {
      edit: edit_allowed?(work_package),
      log_time: log_time_allowed?(work_package),
      move: move_allowed?(work_package),
      copy: move_allowed?(work_package),
      duplicate: copy_allowed?(work_package), # duplicating is another form of copying
      delete: delete_allowed?(work_package),
      manage_subtasks: manage_subtasks_allowed?(work_package),
      comment: comment_allowed?(work_package)
    }
  end

  def edit_allowed?(work_package)
    @edit_cache ||= Hash.new do |hash, project|
      hash[project] = work_package.persisted? &&
                      (user.allowed_to?(:edit_work_packages, project) ||
                       user.allowed_to?(:add_work_package_notes, project))
    end

    @edit_cache[work_package.project]
  end

  def log_time_allowed?(work_package)
    @log_time_cache ||= Hash.new do |hash, project|
      hash[project] = user.allowed_to?(:log_time, project)
    end

    @log_time_cache[work_package.project]
  end

  def move_allowed?(work_package)
    @move_cache ||= Hash.new do |hash, project|
      hash[project] = user.allowed_to?(:move_work_packages, project)
    end

    @move_cache[work_package.project]
  end

  def copy_allowed?(work_package)
    type_active_in_project?(work_package) && add_allowed?(work_package)
  end

  def delete_allowed?(work_package)
    @delete_cache ||= Hash.new do |hash, project|
      hash[project] = user.allowed_to?(:delete_work_packages, project)
    end

    @delete_cache[work_package.project]
  end

  def add_allowed?(work_package)
    @add_cache ||= Hash.new do |hash, project|
      hash[project] = user.allowed_to?(:add_work_packages, project)
    end

    @add_cache[work_package.project]
  end

  def type_active_in_project?(work_package)
    @type_active_cache ||= Hash.new do |hash, project|
      hash[project] = project.types.pluck(:id)
    end

    @type_active_cache[work_package.project].include?(work_package.type_id)
  end

  def manage_subtasks_allowed?(work_package)
    @manage_subtasks_cache ||= Hash.new do |hash, project|
      hash[project] = user.allowed_to?(:manage_subtasks, work_package.project)
    end

    @manage_subtasks_cache[work_package.project]
  end

  def comment_allowed?(work_package)
    @comment_cache ||= Hash.new do |hash, project|
      hash[project] = user.allowed_to?(:add_work_package_notes, work_package.project) ||
                      edit_allowed?(work_package)
    end

    @comment_cache[work_package.project]
  end
end
