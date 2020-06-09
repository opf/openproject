#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

class WorkPackages::ScheduleDependency
  def initialize(work_packages)
    self.work_packages = Array(work_packages)
    self.dependencies = {}
    self.known_work_packages = self.work_packages

    build_dependencies
  end

  def each
    unhandled = dependencies.keys

    while unhandled.any?
      movement = false
      dependencies.each do |scheduled, dependency|
        next unless unhandled.include?(scheduled)
        next unless dependency.met?(unhandled)

        yield scheduled, dependency

        unhandled.delete(scheduled)
        movement = true
      end

      raise "Circular dependency" unless movement
    end
  end

  attr_accessor :work_packages,
                :dependencies,
                :known_work_packages,
                :known_work_packages_by_id,
                :known_work_packages_by_parent_id

  private

  def build_dependencies
    load_all_following(work_packages)
  end

  def load_all_following(work_packages)
    following = load_following(work_packages)

    # Those variables are pure optimizations.
    # We want to reuse the already loaded work packages as much as possible
    # and we want to have them readily available as hashes.
    self.known_work_packages += following
    known_work_packages.uniq!
    self.known_work_packages_by_id = known_work_packages.group_by(&:id)
    self.known_work_packages_by_parent_id = known_work_packages.group_by(&:parent_id)

    new_dependencies = add_dependencies(following)

    if new_dependencies.any?
      load_all_following(new_dependencies.keys)
    end
  end

  def load_following(work_packages)
    WorkPackage
      .hierarchy_tree_following(work_packages)
      .includes(parent_relation: :from,
                follows_relations: :to)
  end

  def find_moved(candidates)
    candidates.select do |following, dependency|
      dependency.ancestors.any? { |ancestor| included_in_follows?(ancestor, candidates) } ||
        dependency.descendants.any? { |descendant| included_in_follows?(descendant, candidates) } ||
        dependency.descendants.any? { |descendant| work_packages.include?(descendant) } ||
        included_in_follows?(following, candidates)
    end
  end

  def included_in_follows?(wp, candidates)
    tos = wp.follows_relations.map(&:to)

    dependencies.slice(*tos).any? ||
      candidates.slice(*tos).any? ||
      (tos & work_packages).any?
  end

  def add_dependencies(dependent_work_packages)
    added = dependent_work_packages.inject({}) do |new_dependencies, dependent_work_package|
      dependency = Dependency.new dependent_work_package, self

      new_dependencies[dependent_work_package] = dependency

      new_dependencies
    end

    moved = find_moved(added)

    newly_added = moved.except(*dependencies.keys)

    dependencies.merge!(moved)

    newly_added
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

    def follows_moved
      tree = ancestors + descendants

      @follows_moved ||= moved_predecessors_from_preloaded(work_package, tree)
    end

    def follows_unmoved
      tree = ancestors + descendants

      @follows_unmoved ||= unmoved_predecessors_from_preloaded(work_package, tree)
    end

    attr_accessor :work_package,
                  :schedule_dependency

    def met?(unhandled_work_packages)
      (descendants & unhandled_work_packages).empty? &&
        (follows_moved.map(&:to) & unhandled_work_packages).empty?
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
          parent + ancestors_from_preloaded(parent.first)
        end
      end || []
    end

    def descendants_from_preloaded(work_package)
      children = known_work_packages_by_parent_id[work_package.id] || []

      children + children.map { |child| descendants_from_preloaded(child) }.flatten
    end

    delegate :known_work_packages,
             :known_work_packages_by_id,
             :known_work_packages_by_parent_id, to: :schedule_dependency

    def scheduled_work_packages
      schedule_dependency.work_packages + schedule_dependency.dependencies.keys
    end

    def moved_predecessors_from_preloaded(work_package, tree)
      ([work_package] + tree)
        .map(&:follows_relations)
        .flatten
        .map do |relation|
          scheduled = scheduled_work_packages.detect { |c| relation.to_id == c.id }

          if scheduled
            relation.to = scheduled
            relation
          end
        end
        .compact
    end

    def unmoved_predecessors_from_preloaded(work_package, tree)
      ([work_package] + tree)
        .map(&:follows_relations)
        .flatten
        .reject do |relation|
          scheduled_work_packages.any? { |m| relation.to_id == m.id }
        end
    end
  end
end
