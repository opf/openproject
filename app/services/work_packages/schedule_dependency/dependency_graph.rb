#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class WorkPackages::ScheduleDependency::DependencyGraph
  attr_reader :dependencies

  def initialize(dependencies)
    @dependencies = dependencies
  end

  def schedule_order
    schedule_order = []
    dependencies.each do |dependency|
      # Find the index of the last dependency the dependency needs to come after.
      index = schedule_order.rindex do |inserted_dependency|
        depends_on?(dependency.work_package, inserted_dependency)
      end

      if index
        schedule_order.insert(index + 1, dependency)
      else
        schedule_order.unshift(dependency)
      end
    end
    schedule_order
  end

  # Returns true if the given work package depends on the work package of the
  # dependency, either directly or transitively.
  def depends_on?(work_package, dependency)
    full_dependencies_of(work_package.id).include?(dependency.work_package.id)
  end

  private

  def full_dependencies_of(work_package_id)
    @full_dependent_ids ||= {}
    @full_dependent_ids[work_package_id] ||= begin
      ids = dependent_ids_for_work_package_id(work_package_id)
      ids += ids.flat_map { full_dependencies_of(_1) }
      ids.uniq
    end
  end

  def dependent_ids_for_work_package_id(id)
    @dependent_ids ||= dependencies.to_h { |dep| [dep.work_package.id, dep.dependent_ids] }
    @dependent_ids[id] || []
  end
end
