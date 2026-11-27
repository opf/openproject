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
    return true if target == Backlogs::Target::InboxId

    candidate_targets.include?(target)
  end

  def refusing(target)
    readonly_members.reject { |work_package| Backlogs::Target.for_work_package(work_package) == target }
  end

  def sprints
    @sprints ||= offered(candidate_sprints)
  end

  def buckets
    @buckets ||= offered(candidate_buckets)
  end

  def inbox?
    return @inbox if defined?(@inbox)

    @inbox = manage_permission? && offers?(Backlogs::Target::InboxId)
  end

  private

  def candidate_targets
    @candidate_targets ||= Set.new(
      [Backlogs::Target::InboxId] +
      (candidate_sprints + candidate_buckets).map { |container| Backlogs::Target.for(container) }
    )
  end

  def readonly_members
    @readonly_members ||= work_packages.select(&:readonly_status?)
  end

  def offered(containers)
    return [] unless manage_permission?

    containers.select { |container| offers?(Backlogs::Target.for(container)) }
  end

  def offers?(target)
    refusing(target).empty? &&
      work_packages.any? { |wp| Backlogs::Target.for_work_package(wp) != target }
  end
end
