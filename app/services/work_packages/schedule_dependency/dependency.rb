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

class WorkPackages::ScheduleDependency::Dependency
  def initialize(work_package, schedule_dependency)
    self.work_package = work_package
    self.schedule_dependency = schedule_dependency
  end

  attr_accessor :work_package,
                :schedule_dependency

  # Returns the work package ids that this work package directly depends on to
  # determine its own dates. This is used for the order of the dates
  # computations.
  #
  # The dates of a work package depend on its descendants and predecessors
  # dates.
  def dependent_ids
    @dependent_ids ||= (descendants + moving_predecessors).map(&:id).uniq
  end

  def moving_predecessors
    @moving_predecessors ||= follows_relations
      .map(&:to)
      .filter { |predecessor| schedule_dependency.moving?(predecessor) }
  end

  def soonest_start_date
    @soonest_start_date ||=
      follows_relations
        .filter_map(&:successor_soonest_start)
        .max
  end

  def start_date
    descendants_dates.min
  end

  def due_date
    descendants_dates.max
  end

  def has_descendants?
    descendants.any?
  end

  private

  def descendants
    schedule_dependency.descendants(work_package)
  end

  def follows_relations
    schedule_dependency.follows_relations(work_package)
  end

  def descendants_dates
    descendants.filter_map(&:due_date) + descendants.filter_map(&:start_date)
  end
end
