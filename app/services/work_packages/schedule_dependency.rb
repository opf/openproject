#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

class WorkPackages::ScheduleDependency
  def initialize(work_packages)
    self.work_packages = Array(work_packages)

    following = load_following

    # Those variables are pure optimizations.
    # We want to reuse the already loaded work packages as much as possible
    # and we want to have them readily available as hashes.
    self.known_work_packages_by_id = (self.work_packages + following).index_by(&:id)
    self.known_work_packages_by_parent_id = fetch_descendants.group_by(&:parent_id)

    self.dependencies = create_dependencies(following)
  end

  # Returns each dependency in the order necessary for scheduling:
  #   * successors after predecessors
  #   * ancestors after descendants
  def in_schedule_order
    DependencyGraph.new(dependencies.values).schedule_order.each do |dependency|
      yield dependency.work_package, dependency
    end
  end

  attr_accessor :work_packages,
                :dependencies,
                :known_work_packages_by_id,
                :known_work_packages_by_parent_id

  def scheduled_work_packages_by_id
    @scheduled_work_packages_by_id ||= (work_packages + dependencies.keys).index_by(&:id)
  end

  private

  def load_following
    WorkPackage
      .for_scheduling(work_packages)
      .includes(follows_relations: :to)
  end

  def create_dependencies(dependent_work_packages)
    dependent_work_packages.index_with { |work_package| Dependency.new(work_package, self) }
  end

  # Use a mixture of work packages that are already loaded to be scheduled
  # themselves but also load all the rest of the descendants.
  #
  # There are two cases in which descendants are not loaded for scheduling:
  #   * manual scheduling: A descendant is either scheduled manually itself or
  #     all of its descendants are scheduled manually.
  #   * sibling: the descendant is not below a work package to be scheduled
  #     (e.g. one following another) but below an ancestor of a schedule work
  #     package.
  def fetch_descendants
    descendants = known_work_packages_by_id.values

    descendants + WorkPackage
                    .with_ancestor(descendants)
                    .includes(follows_relations: :to)
                    .where.not(id: known_work_packages_by_id.keys)
  end
end
