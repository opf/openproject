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
    # Both tasks take optional work package ids, e.g. rake "target_versions:stale:report[15,16]",
    # to sanity-check a few items; without arguments the run covers everything.
    remediation = ->(args) {
      ids = ([args[:work_package_ids]] + args.extras).compact.map { it.to_s.strip.to_i }
      WorkPackages::StaleTargetVersionRemediation.new(work_package_ids: ids)
    }

    desc "Report target versions stale-reinstated by the frozen version_id column"
    task :report, [:work_package_ids] => :environment do |_task, args|
      $stdout.sync = true
      remediation.call(args).report
    end

    desc "Remove target versions stale-reinstated by the frozen version_id column"
    task :fix, [:work_package_ids] => :environment do |_task, args|
      $stdout.sync = true
      remediation.call(args).apply
    end
  end
end
