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
    self.known_work_packages_by_id = (self.work_packages + following).group_by(&:id).transform_values(&:first)
    self.known_work_packages_by_parent_id = fetch_descendants.group_by(&:parent_id)

    self.dependencies = create_dependencies(following)
  end

  # Returns each dependency in the order necessary for scheduling:
  # * successors after predecessors
  # * ancestors after descendants
  def in_schedule_order
    schedule_order = []

    dependencies
      .each_value do |dependency|
      # Find the index of the last dependency the dependency needs to come after.
      index = schedule_order.rindex do |inserted_dependency|
        dependency.dependent_ids.include?(inserted_dependency.work_package.id)
      end

      if index
        schedule_order.insert(index + 1, dependency)
      else
        schedule_order.unshift(dependency)
      end
    end

    schedule_order.each do |dependency|
      yield dependency.work_package, dependency
    end
  end

  attr_accessor :work_packages,
                :dependencies,
                :known_work_packages_by_id,
                :known_work_packages_by_parent_id

  def scheduled_work_packages_by_id
    @scheduled_work_packages_by_id ||= (work_packages + dependencies.keys).group_by(&:id).transform_values(&:first)
  end

  private

  def load_following
    WorkPackage
      .for_scheduling(work_packages)
      .includes(follows_relations: :to)
  end

  def create_dependencies(dependent_work_packages)
    dependent_work_packages.inject({}) do |new_dependencies, dependent_work_package|
      new_dependencies[dependent_work_package] = Dependency.new dependent_work_package, self
      new_dependencies
    end
  end

  # Use a mixture of work packages that are already loaded to be scheduled themselves but also load
  # all the rest of the descendants. There are two cases in which descendants are not loaded for scheduling:
  # * manual scheduling: A descendant is either scheduled manually itself or all of its descendants are scheduled manually.
  # * sibling: the descendant is not below a work package to be scheduled (e.g. one following another) but below an ancestor of
  #            a schedule work package.
  def fetch_descendants
    descendants = known_work_packages_by_id.values

    descendants + WorkPackage
                    .with_ancestor(descendants)
                    .where.not(id: known_work_packages_by_id.keys)
  end

  class Dependency
    def initialize(work_package, schedule_dependency)
      self.schedule_dependency = schedule_dependency
      self.work_package = work_package
    end

    def ancestors
      @ancestors ||= ancestors_from_preloaded(work_package)
    end

    def descendants
      @descendants ||= descendants_from_preloaded(work_package)
    end

    def descendants_ids
      @descendants_ids ||= descendants.map(&:id)
    end

    def follows_moved
      @follows_moved ||= moved_predecessors_from_preloaded(work_package)
    end

    def follows_unmoved
      @follows_unmoved ||= unmoved_predecessors_from_preloaded(work_package)
    end

    def follows_moved_ids
      @follows_moved_ids ||= follows_moved.map(&:to).map(&:id)
    end

    attr_accessor :work_package,
                  :schedule_dependency

    def dependent_ids
      @dependent_ids ||= descendants_ids + follows_moved_ids
    end

    def met?(unhandled_ids)
      (descendants_ids & unhandled_ids).empty? &&
        (follows_moved_ids & unhandled_ids).empty?
    end

    def max_date_of_followed
      (follows_moved + follows_unmoved)
        .map(&:successor_soonest_start)
        .compact
        .max
    end

    def start_date
      descendants_dates.min
    end

    def due_date
      descendants_dates.max
    end

    private

    def descendants_dates
      (descendants.map(&:due_date) + descendants.map(&:start_date)).compact
    end

    def ancestors_from_preloaded(work_package)
      if work_package.parent_id
        parent = known_work_packages_by_id[work_package.parent_id]

        if parent
          [parent] + ancestors_from_preloaded(parent)
        end
      else
        []
      end
    end

    def descendants_from_preloaded(work_package)
      children = known_work_packages_by_parent_id[work_package.id] || []

      children + children.map { |child| descendants_from_preloaded(child) }.flatten
    end

    delegate :known_work_packages_by_id,
             :known_work_packages_by_parent_id,
             :scheduled_work_packages_by_id, to: :schedule_dependency

    def scheduled_work_packages
      schedule_dependency.work_packages + schedule_dependency.dependencies.keys
    end

    def moved_predecessors_from_preloaded(work_package)
      ([work_package] + ancestors + descendants)
        .map(&:follows_relations)
        .flatten
        .map do |relation|
          scheduled = scheduled_work_packages_by_id[relation.to_id]

          if scheduled
            relation.to = scheduled
            relation
          end
        end
        .compact
    end

    def unmoved_predecessors_from_preloaded(work_package)
      ([work_package] + ancestors + descendants)
        .map(&:follows_relations)
        .flatten
        .reject do |relation|
          scheduled_work_packages_by_id[relation.to_id].present?
        end
    end
  end
end
