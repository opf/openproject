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

namespace :target_versions do
  namespace :stale do
    # Both tasks take optional arguments to narrow the run; without any, it covers everything.
    # Numeric arguments are work package ids, anything else is parsed as a time and bounds the
    # repair journals' creation time (first = from, second = to). Examples:
    #   rake "target_versions:stale:report[15,16]"
    #   rake "target_versions:stale:fix[2026-08-27T08:00:00+02:00,2026-08-27T09:00:00+02:00]"
    #   rake "target_versions:stale:fix[15,2026-08-27T08:00:00+02:00,2026-08-27T09:00:00+02:00]"
    parse_time = ->(raw) {
      unless raw.match?(/\A\d{4}-\d{2}-\d{2}/)
        raise ArgumentError, "unrecognized argument: #{raw} (work package id or ISO8601 time expected)"
      end

      Time.zone.parse(raw) || raise(ArgumentError, "unparsable time: #{raw}")
    }

    remediation = ->(args) {
      ids, times = [args[:scope], *args.extras].map { it.to_s.strip }
                                               .compact_blank
                                               .partition { it.match?(/\A\d+\z/) }
      from, to, overflow = times.map { parse_time.call(it) }
      raise ArgumentError, "at most two time bounds (from, to) are supported" if overflow
      raise ArgumentError, "the from time must come before the to time" if from && to && from > to

      WorkPackages::StaleTargetVersionRemediation.new(
        work_package_ids: ids.map(&:to_i),
        created_between: (from || to) && Range.new(from, to)
      )
    }

    desc "Report target versions stale-reinstated by the frozen version_id column"
    task :report, [:scope] => :environment do |_task, args|
      $stdout.sync = true
      remediation.call(args).report
    end

    desc "Remove target versions stale-reinstated by the frozen version_id column"
    task :fix, [:scope] => :environment do |_task, args|
      $stdout.sync = true
      remediation.call(args).apply
    end
  end
end
