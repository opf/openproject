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

class WorkPackages::EnableMultipleVersionsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(total_limit: 1)
  queue_with_priority :above_normal

  class EnablingFailed < StandardError; end

  def self.in_progress? = GoodJob::Job.where(job_class: name).exists?(finished_at: nil)

  def perform
    return if Setting.work_package_multiple_versions?

    # Must run before the flip, or a work package with a version_id but no
    # target row reads as having no target version once multi-value mode is on.
    repaired_ids = backfill_missing_target_versions
    journal_repaired_work_packages(repaired_ids)
    enable_multiple_versions!
  end

  private

  def backfill_missing_target_versions
    repaired_ids = ActiveRecord::Base.connection.select_values(<<~SQL.squish)
      INSERT INTO work_package_versions (work_package_id, version_id, kind, created_at, updated_at)
          SELECT work_packages.id, work_packages.version_id, 'target', now(), now()
          FROM work_packages
          INNER JOIN versions ON versions.id = work_packages.version_id
          WHERE work_packages.version_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1 FROM work_package_versions
              WHERE work_package_versions.work_package_id = work_packages.id
                AND work_package_versions.version_id = work_packages.version_id
                AND work_package_versions.kind = 'target'
            )
      ON CONFLICT (work_package_id, version_id, kind) DO NOTHING
      RETURNING work_package_id
    SQL

    log_repaired_target_versions(repaired_ids.count)
    repaired_ids
  end

  # A repaired row diverges from the last journal's snapshot, so without a
  # catch-up journal the next unrelated save would record the change as if
  # that editor had set the target version.
  def journal_repaired_work_packages(work_package_ids)
    return if work_package_ids.empty?

    cause = Journal::CausedBySystemUpdate.new(feature: "target_versions_repaired")

    Journal::NotificationConfiguration.with(false) do
      WorkPackage.where(id: work_package_ids).find_each do |work_package|
        Journals::CreateService.new(work_package, User.system).call(cause:)
      end
    end
  end

  # Every write path mirrors version_id into a target row already, so a non-zero
  # count means something reached the column directly and is worth investigating.
  def log_repaired_target_versions(count)
    return if count.zero?

    Rails.logger.warn(
      "[#{self.class.name}] Added #{count} missing target version row(s) before enabling multiple versions."
    )
  end

  def enable_multiple_versions!
    # Settings::UpdateService strips every scalar it is given, so a boolean has to arrive as a string.
    result = Settings::UpdateService.new(user: User.system).call(work_package_multiple_versions: "1")

    raise EnablingFailed, "Failed to enable multiple versions: #{result.message}" unless result.success?
  end
end
