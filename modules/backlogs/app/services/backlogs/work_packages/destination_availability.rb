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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Backlogs::WorkPackages::DestinationAvailability
  attr_reader :project, :user, :work_packages

  def initialize(project:, user:, work_packages:)
    @project = project
    @user = user
    @work_packages = work_packages
  end

  def manage_permission?
    return @manage_permission if defined?(@manage_permission)

    @manage_permission = user.allowed_in_project?(:manage_sprint_items, project)
  end

  def candidate_sprints
    @candidate_sprints ||= Sprint.assignable(project:, user:).order_by_date.to_a
  end

  def candidate_buckets
    @candidate_buckets ||= BacklogBucket.assignable(project:, user:).to_a
  end

  def candidate?(target)
    candidate_targets.include?(target)
  end

  def refusing(target)
    work_packages.reject { |work_package| accepts?(work_package, target) }
  end

  def sprints = offered(candidate_sprints)
  def buckets = offered(candidate_buckets)

  private

  def candidate_targets
    @candidate_targets ||= Set.new(
      [Backlogs::Target::InboxId] +
      (candidate_sprints + candidate_buckets).map { |container| Backlogs::Target.for(container) }
    )
  end

  def accepts?(work_package, target)
    !work_package.readonly_status? || Backlogs::Target.for_work_package(work_package) == target
  end

  def offered(containers)
    return [] unless manage_permission?

    containers.select do |container|
      target = Backlogs::Target.for(container)
      refusing(target).empty? &&
        work_packages.any? { |wp| Backlogs::Target.for_work_package(wp) != target }
    end
  end
end
