# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Get the schedule order and information for work packages that have just been
# moved dates.
#
# The schedule order is given by calling +in_schedule_order+ with a block. The
# dependency object given as a block parameter contains helpful information for
# setting the work package start and due dates.
#
# About the terminology:
# * moved work packages have just been changed and rescheduled with moved dates.
# * moving work packages are impacted by the rescheduling of moved work package,
#   and will potentially be rescheduled and will be moving to other dates.
# * unmoving work packages are not impacted by the rescheduling of moved work
#   package, but are necessary to accurately determine the new start and due
#   dates of the moving work packages.
class WorkPackages::ScheduleDependency
  attr_accessor :dependencies, :switching_to_automatic_mode

  def initialize(moved_work_packages, switching_to_automatic_mode: [])
    self.moved_work_packages = Array(moved_work_packages)
    self.switching_to_automatic_mode = Array(switching_to_automatic_mode)

    preload_scheduling_data

    self.dependencies = create_dependencies
  end

  # Returns each dependency in the order necessary for scheduling:
  #   * successors after predecessors
  #   * ancestors after descendants
  def in_schedule_order
    DependencyGraph.new(dependencies.values).schedule_order.each do |dependency|
      yield dependency.work_package, dependency
    end
  end

  def work_package_by_id(id)
    return unless id

    @work_package_by_id ||= known_work_packages.index_by(&:id)
    @work_package_by_id[id]
  end

  def children_by_parent_id(parent_id)
    return [] unless parent_id

    @children_by_parent_id ||= known_work_packages.group_by(&:parent_id)
    @children_by_parent_id[parent_id] || []
  end

  def moving?(work_package)
    @moving_work_packages_set ||= Set.new((moved_work_packages + moving_work_packages).map(&:id))
    @moving_work_packages_set.include?(work_package.id)
  end

  def parent_of(work_package)
    work_package_by_id(work_package.parent_id)
  end

  def ancestors(work_package)
    @ancestors ||= {}
    @ancestors[work_package] ||= begin
      parent = parent_of(work_package)

      if parent
        [parent, *ancestors(parent)]
      else
        []
      end
    end
  end

  def automatically_scheduled_ancestors(work_package)
    @automatically_scheduled_ancestors ||= {}
    @automatically_scheduled_ancestors[work_package] ||= begin
      work_packages_to_process = [work_package]
      result = []
      processed_ids = Set.new

      while current = work_packages_to_process.shift
        processed_ids.add(current.id)

        parent = parent_of(current)

        if parent&.schedule_automatically?
          result << parent unless parent.id == work_package.id
          work_packages_to_process << parent unless processed_ids.include?(parent.id)
        end
      end
      result
    end
  end

  def descendants(work_package)
    # Avoid using WorkPackage.with_ancestors to save database requests.
    # All needed data is already loaded.
    @descendants ||= {}
    @descendants[work_package] ||= begin
      work_packages_to_process = [work_package]
      result = []
      processed_ids = Set.new

      while current = work_packages_to_process.shift
        processed_ids.add(current.id)

        children = children_by_parent_id(current.id)

        # Avoid cycles by rejecting children that have already been processed
        children.reject! { |child| processed_ids.include?(child.id) }

        result.concat(children)
        work_packages_to_process.concat(children)
      end

      result
    end
  end

  # Get relations of type follows for which the given work package is a direct
  # follower, or an indirect follower (through parent and/or children).
  #
  # Used by +Dependency#dependent_ids+ to get work packages that must be
  # scheduled prior to the given work package.
  def follows_relations(work_package)
    @follows_relations ||= {}
    @follows_relations[work_package] ||= all_direct_and_indirect_follows_relations_for(work_package)
  end

  private

  attr_accessor :known_follows_relations,
                :moved_work_packages

  def all_direct_and_indirect_follows_relations_for(work_package)
    self_and_automatic_ancestors = [work_package] + automatically_scheduled_ancestors(work_package)
    follows_relations_by_follower_id
      .fetch_values(*self_and_automatic_ancestors.pluck(:id)) { [] }
      .flatten
      .uniq
  end

  def follows_relations_by_follower_id
    @follows_relations_by_follower_id ||= known_follows_relations.group_by(&:from_id)
  end

  def create_dependencies
    (moved_work_packages + moving_work_packages)
      .filter { |work_package| automatically_scheduled?(work_package) }
      .index_with { |work_package| Dependency.new(work_package, self) }
  end

  def automatically_scheduled?(work_package)
    work_package.schedule_automatically? || switching_to_automatic_mode.include?(work_package)
  end

  def moving_work_packages
    @moving_work_packages ||= WorkPackage
                                .for_scheduling(moved_work_packages, switching_to_automatic_mode:)
  end

  # All work packages preloaded during initialization.
  # See +#preload_scheduling_data+
  def known_work_packages
    @known_work_packages ||= []
  end

  def preload_scheduling_data
    # moved work packages are the work packages that have just been rescheduled
    # to new dates
    known_work_packages.concat(moved_work_packages)

    # moving work packages are ancestors, descendants, and successors impacted
    # by the moved work packages
    known_work_packages.concat(moving_work_packages)

    # preload the unmoving descendants of moved and moving work packages, as
    # they can influence the dates computation of moving work packages
    known_work_packages.concat(fetch_unmoving_descendants)

    # preload the predecessors relations
    preload_follows_relations

    # preload unmoving predecessors, as they influence the computation of Relation#successor_soonest_start
    known_work_packages.concat(fetch_unmoving_predecessors)

    # rehydrate the predecessors and followers of follows relations
    rehydrate_follows_relations
  end

  # Returns all the descendants of moved and moving work packages that are not
  # already loaded.
  #
  # There are two cases in which descendants are not loaded for scheduling
  # because they will not move:
  #   * manual scheduling: A descendant is either scheduled manually itself or
  #     all of its descendants are scheduled manually.
  #   * sibling: the descendant is not below a moving work package but below an
  #     ancestor of a moving work package.
  def fetch_unmoving_descendants
    WorkPackage
      .with_ancestor(known_work_packages)
      .where.not(id: known_work_packages.map(&:id))
      .distinct
  end

  # Load all the predecessors of follows relations that are not already loaded.
  def fetch_unmoving_predecessors
    not_yet_loaded_predecessors_ids = known_follows_relations.map(&:to_id) - known_work_packages.map(&:id)
    WorkPackage
      .where(id: not_yet_loaded_predecessors_ids)
  end

  # Preload the predecessors relations for preloaded work packages.
  def preload_follows_relations
    raise "must be called only once" unless known_follows_relations.nil?

    self.known_follows_relations = Relation.follows.where(from_id: known_work_packages.map(&:id))
  end

  # rehydrate the #to and #from members of the preloaded follows relations, to
  # prevent triggering additional database requests when computing soonest
  # start.
  def rehydrate_follows_relations
    known_follows_relations.each do |relation|
      relation.from = work_package_by_id(relation.from_id)
      relation.to = work_package_by_id(relation.to_id)
    end
  end
end
