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

class CreatedResolved
  def initialize(sprint, project, _burn_direction = nil)
    @sprint = sprint
    @project = project
    @sprint_id = sprint.id

    make_date_series sprint

    make_series :wp_created, work_package_counts(sprint_journals)
    make_series :wp_resolved, work_package_counts(sprint_journals.where(status_id: resolved_statuses))

    determine_max
  end

  attr_reader :days, :sprint_id, :max

  def series(_select = :active)
    @available_series
  end

  private

  attr_reader :sprint, :project

  def make_date_series(sprint)
    @days = if sprint.date_range_set?
              Day.working.from_range(from: sprint.start_date, to: sprint.finish_date).map(&:date)
            else
              []
            end
  end

  def work_package_counts(journals)
    counts = WorkPackages::JournalTimeline
               .new(journals, ticks:)
               .relation
               .group(:tick)
               .count
               .transform_keys(&:to_i)

    ticks.map { (counts[it.to_i] || 0).to_f }
  end

  def sprint_journals
    Journal::WorkPackageJournal.where(project_id: project.id, sprint_id: sprint.id)
  end

  def resolved_statuses
    Status.where(is_closed: true)
          .or(Status.where(id: project.done_statuses.reorder(nil)))
          .reorder(nil)
  end

  def ticks
    @ticks ||= elapsed_days.map { User.current.time_zone.local(it.year, it.month, it.day, 23, 59, 59) }
  end

  def elapsed_days
    return [] unless sprint.date_range_set?

    last_day = Time.zone.today.clamp(sprint.start_date, sprint.finish_date)

    Day.working.from_range(from: sprint.start_date, to: last_day).map(&:date)
  end

  def make_series(name, data)
    @available_series ||= {}
    s = OpenProject::Backlogs::CreatedResolved::Series.new(name, :workpackages, data)
    @available_series[name] = s.data
    instance_variable_set(:"@#{name}", s.data)
  end

  def determine_max
    @max = {
      wp_created: @available_series[:wp_created].compact.max || 0.0,
      wp_resolved: @available_series[:wp_resolved].compact.max || 0.0
    }
  end
end
