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

class WorkPackages::ScheduleDependency::Dependency
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
    @follows_moved ||= moved_predecessors_from_preloaded(work_package)
  end

  def follows_unmoved
    @follows_unmoved ||= unmoved_predecessors_from_preloaded(work_package)
  end

  attr_accessor :work_package,
                :schedule_dependency

  # Returns the work package ids that the work package directly depends on.
  #
  # The dates of a work package depend on its descendants and predecessors
  # dates.
  def dependent_ids
    @dependent_ids ||= (descendants + follows_moved.map(&:to)).map(&:id)
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
    parent = known_work_packages_by_id[work_package.parent_id]

    if parent
      [parent] + ancestors_from_preloaded(parent)
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
