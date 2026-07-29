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

# Writes a journal entry on each work package that was associated with a sprint
# during the version-to-sprint migration. Runs asynchronously after the migration
# so that the migration itself does not block on journal creation.
module Backlogs
  class MigrateVersionSprintJournalsJob < ApplicationJob
    def perform
      system_user = User.system

      Journal::NotificationConfiguration.with(false) do
        qualified_work_packages.find_each do |work_package|
          cause = Journal::CausedBySystemUpdate.new(
            feature: "sprint_migration",
            version_name: work_package.version_name
          )
          Journals::CreateService
            .new(work_package, system_user)
            .call(cause:)
        end
      end
    end

    private

    # Reads the version name through work_package_versions where available,
    # falling back to the legacy version_id column: a worker can pick this job
    # up between the migration enqueuing it and the much later migration that
    # introduces work_package_versions.
    def qualified_work_packages
      scope = WorkPackage.joins(:sprint)

      if work_package_versions_available?
        # A work package can have several target versions; journal once, for
        # the primary one (lowest version id, matching the version_id mirror).
        scope
          .joins(<<~SQL.squish)
            INNER JOIN work_package_versions
              ON work_package_versions.work_package_id = work_packages.id
              AND work_package_versions.kind = 'target'
              AND work_package_versions.version_id = (
                SELECT MIN(wpv.version_id) FROM work_package_versions wpv
                WHERE wpv.work_package_id = work_packages.id AND wpv.kind = 'target'
              )
          SQL
          .joins("INNER JOIN versions ON versions.id = work_package_versions.version_id")
          .select("work_packages.*, versions.name AS version_name")
      else
        scope
          .joins("INNER JOIN versions ON versions.id = work_packages.version_id")
          .select("work_packages.*, versions.name AS version_name")
      end
    end

    def work_package_versions_available?
      WorkPackage.connection.table_exists?("work_package_versions")
    end
  end
end
