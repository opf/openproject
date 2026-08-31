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

class MigrateVersionsToSprints < ActiveRecord::Migration[8.0]
  class MigrationVersionSetting < ApplicationRecord
    self.table_name = "version_settings"

    DISPLAY_LEFT = 2
    DISPLAY_RIGHT = 3
  end

  class MigrationWorkPackage < ApplicationRecord
    self.table_name = "work_packages"
  end

  class MigrationVersion < ApplicationRecord
    self.table_name = "versions"

    has_many :work_packages,
             class_name: "MigrateVersionsToSprints::MigrationWorkPackage",
             foreign_key: "version_id"

    has_many :version_settings,
             class_name: "MigrateVersionsToSprints::MigrationVersionSetting",
             foreign_key: "version_id"
  end

  def up
    return if sprint_versions_with_work_package_ids.none?

    sprint_versions_with_work_package_ids.find_each do |version|
      sprint = create_sprint(version)
      migrate_work_packages_to_sprint(sprint, version.wp_ids)
    end

    Backlogs::MigrateVersionSprintJournalsJob.perform_later
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def sprint_versions_with_work_package_ids
    # Load versions used as sprints including work package ids associated with the version.
    # Since the same version can be used as a sprint in one project but not in another,
    # the work package ids are filtered by projects where the version is used as a sprint.

    MigrationVersion
      .joins(:version_settings, :work_packages)
      .where(version_settings: { display: [MigrationVersionSetting::DISPLAY_LEFT, MigrationVersionSetting::DISPLAY_RIGHT] })
      .where("work_packages.project_id = version_settings.project_id")
      .group("versions.id")
      .select("versions.*, array_agg(DISTINCT work_packages.id) AS wp_ids")
  end

  def create_sprint(version)
    Sprint.create!(
      name: version.name,
      project_id: version.project_id,
      status: version.status == "open" ? "in_planning" : "completed",
      start_date: version.start_date,
      finish_date: version.effective_date
    )
  end

  def migrate_work_packages_to_sprint(sprint, wp_ids)
    WorkPackage.where(id: wp_ids).update_all(sprint_id: sprint.id)
  end
end
