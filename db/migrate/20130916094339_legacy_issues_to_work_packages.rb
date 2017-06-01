#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require_relative 'migration_utils/utils'

class LegacyIssuesToWorkPackages < ActiveRecord::Migration[4.2]
  include Migration::Utils

  class ExistingWorkPackagesError < ::StandardError
  end

  class ExistingLegacyIssuesError < ::StandardError
  end

  def up
    raise_on_existing_work_package_entries
    copy_legacy_issues_to_work_packages
    reset_public_key_sequence_in_postgres 'work_packages'
  end

  def down
    raise_on_existing_legacy_issue_entries
    copy_work_packages_to_legacy_issues
  end

  private

  def raise_on_existing_work_package_entries
    existing_work_packages = select_all <<-SQL
      SELECT *
      FROM work_packages
    SQL

    unless existing_work_packages.empty?
      raise ExistingWorkPackagesError, <<-MESSAGE.split("\n").map(&:strip!).join(' ') + "\n"
        There are already entries in the work_packages table.
        This migration assumes that there are none.
      MESSAGE
    end
  end

  def copy_legacy_issues_to_work_packages
    execute <<-SQL
      INSERT INTO work_packages
        (
          id,
          type_id,
          project_id,
          subject,
          description,
          due_date,
          category_id,
          status_id,
          assigned_to_id,
          priority_id,
          fixed_version_id,
          author_id,
          lock_version,
          done_ratio,
          estimated_hours,
          created_at,
          updated_at,
          start_date,
          planning_element_status_comment,
          deleted_at,
          parent_id,
          responsible_id,
          planning_element_status_id,
          sti_type,
          root_id,
          lft,
          rgt
        )
      SELECT
        id,
        tracker_id,
        project_id,
        subject,
        description,
        due_date,
        category_id,
        status_id,
        assigned_to_id,
        priority_id,
        fixed_version_id,
        author_id,
        lock_version,
        done_ratio,
        estimated_hours,
        created_on,
        updated_on,
        start_date,
        '',
        NULL,
        parent_id,
        NULL,
        NULL,
        NULL,
        root_id,
        lft,
        rgt
      FROM legacy_issues
    SQL
  end

  def raise_on_existing_legacy_issue_entries
    existing_legacy_issues = select_all <<-SQL
      SELECT *
      FROM legacy_issues
    SQL

    if existing_legacy_issues.size > 0
      raise ExistingLegacyIssuesError, <<-MESSAGE.split("\n").map(&:strip!).join(' ') + "\n"
        There are already entries in the legacy_issues table.
        This migration assumes that there are none.
      MESSAGE
    end
  end

  def copy_work_packages_to_legacy_issues
    execute <<-SQL
      INSERT INTO legacy_issues
        (
          id,
          tracker_id,
          project_id,
          subject,
          description,
          due_date,
          category_id,
          status_id,
          assigned_to_id,
          priority_id,
          fixed_version_id,
          author_id,
          lock_version,
          done_ratio,
          estimated_hours,
          created_on,
          updated_on,
          start_date,
          parent_id,
          root_id,
          lft,
          rgt
        )
      SELECT
        id,
        type_id,
        project_id,
        subject,
        description,
        due_date,
        category_id,
        status_id,
        assigned_to_id,
        priority_id,
        fixed_version_id,
        author_id,
        lock_version,
        done_ratio,
        estimated_hours,
        created_at,
        updated_at,
        start_date,
        parent_id,
        root_id,
        lft,
        rgt
      FROM work_packages
    SQL
  end
end
