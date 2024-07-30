#  OpenProject is an open source project management software.
#  Copyright (C) the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

class WorkPackages::UpdateAncestors::Loader
  DESCENDANT_ATTRIBUTES = {
    id: "id",
    parent_id: "parent_id",
    estimated_hours: "estimated_hours",
    remaining_hours: "remaining_hours",
    status_excluded_from_totals: "statuses.excluded_from_totals",
    schedule_manually: "schedule_manually",
    ignore_non_working_days: "ignore_non_working_days"
  }.freeze

  WorkPackageLikeStruct = Data.define(*DESCENDANT_ATTRIBUTES.keys) do
    def included_in_totals_calculation?
      !status_excluded_from_totals
    end
  end

  def initialize(work_package, include_former_ancestors)
    self.work_package = work_package
    self.include_former_ancestors = include_former_ancestors
  end

  def select
    [work_package, *ancestors]
      .reject(&:destroyed?)
      .select do |work_package|
        yield work_package, self
      end
  end

  def descendants_of(queried_work_package)
    @descendants ||= Hash.new do |hash, wp|
      hash[wp] = replaced_related_descendants(wp)
    end

    @descendants[queried_work_package]
  end

  def children_of(queried_work_package)
    @children ||= Hash.new do |hash, wp|
      hash[wp] = descendants_of(wp).select { |d| d.parent_id == wp.id }
    end

    @children[queried_work_package]
  end

  private

  attr_accessor :work_package,
                :include_former_ancestors

  # Contains both the new as well as the former ancestors in ascending order from the leaves up (breadth first).
  def ancestors
    @ancestors ||= if include_former_ancestors
                     former_ancestors.reverse.inject(current_ancestors) do |ancestors, former_ancestor|
                       index = ancestors.index { |ancestor| ancestor.id == former_ancestor.parent_id }
                       ancestors.insert(index || current_ancestors.length, former_ancestor)
                       ancestors
                     end
                   else
                     current_ancestors
                   end
  end

  # Replace descendants by ancestors if they are the same.
  # This can e.g. be the case in scenario of
  # grandparent
  #      |
  #    parent
  #      |
  # work_package
  #
  # when grandparent used to be the direct parent of work_package (the work_package moved down the hierarchy).
  # Then grandparent and parent are already in ancestors.
  # Parent might be modified during the UpdateAncestorsService run,
  # and the descendants of grandparent need to have the updated value.
  def replaced_related_descendants(queried_work_package)
    related_descendants(queried_work_package).map do |leaf|
      if work_package.id == leaf.id
        work_package
      elsif (ancestor = ancestors.detect { |a| a.id == leaf.id })
        ancestor
      else
        leaf
      end
    end
  end

  def related_descendants(queried_work_package)
    scope = queried_work_package
              .descendants
              .where.not(id: queried_work_package.id)

    scope
      .left_joins(:status)
      .pluck(*DESCENDANT_ATTRIBUTES.values)
      .map { |p| WorkPackageLikeStruct.new(**DESCENDANT_ATTRIBUTES.keys.zip(p).to_h) }
  end

  # Returns the current ancestors sorted by distance (called generations in the table)
  # so the order is parent, grandparent, ..., root.
  def current_ancestors
    @current_ancestors ||= work_package.ancestors.includes(:status).where.not(id: former_ancestors.map(&:id)).to_a
  end

  # Returns the former ancestors sorted by distance (called generations in the table)
  # so the order is former parent, former grandparent, ..., former root.
  def former_ancestors
    @former_ancestors ||= if previous_parent_id && include_former_ancestors
                            parent = WorkPackage.find(previous_parent_id)
                            parent.self_and_ancestors
                          else
                            []
                          end
  end

  ##
  # Get the previous parent ID
  # This could either be +parent_id_was+ if parent was changed
  # (when work_package was saved/destroyed)
  # Or the set parent before saving
  def previous_parent_id
    if work_package.parent_id && work_package.destroyed?
      work_package.parent_id
    elsif work_package.parent_id.nil? && work_package.parent_id_was
      work_package.parent_id_was
    else
      previous_change_parent_id
    end
  end

  def previous_change_parent_id
    previous = work_package.previous_changes

    previous_parent_changes = previous[:parent_id] || previous[:parent]

    previous_parent_changes&.first
  end
end
