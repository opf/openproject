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

  def permitted?(target)
    user.allowed_in_project?(:manage_sprint_items, project) &&
      candidate?(target) &&
      work_packages.all? { |work_package| free?(work_package) || current_target(work_package) == target }
  end

  def sprints
    sprint_candidates.select { |sprint| offered?(Backlogs::Target.for(sprint)) }
  end

  def buckets
    bucket_candidates.select { |bucket| offered?(Backlogs::Target.for(bucket)) }
  end

  def inbox?
    offered?(Backlogs::Target::InboxId)
  end

  # The members that cannot enter the target: a work package frozen by its
  # status stays where it is, so only its own destination accepts it.
  def refusing(target)
    work_packages.reject { |work_package| free?(work_package) || current_target(work_package) == target }
  end

  # Target candidacy alone, without the per-member arm of permitted?: the
  # batch move reports which members refused rather than collapsing the whole
  # batch into one anonymous failure.
  def candidate?(target)
    case target
    in Backlogs::Target::SprintId
      sprint_candidates.any? { |sprint| sprint.id == target.list_id }
    in Backlogs::Target::BucketId
      bucket_candidates.any? { |bucket| bucket.id == target.list_id }
    in Backlogs::Target::InboxId
      true
    else
      false
    end
  end

  private

  def offered?(target)
    permitted?(target) && work_packages.any? { |work_package| current_target(work_package) != target }
  end

  def sprint_candidates
    @sprint_candidates ||= Sprint.assignable(project:, user:).order_by_date.to_a
  end

  def bucket_candidates
    @bucket_candidates ||= BacklogBucket.for_project(project).order_alphabetically.to_a
  end

  def free?(work_package)
    !work_package.readonly_status?
  end

  def current_target(work_package)
    Backlogs::Target.for_work_package(work_package)
  end
end
