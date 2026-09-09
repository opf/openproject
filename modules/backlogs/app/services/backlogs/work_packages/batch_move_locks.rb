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

class Backlogs::WorkPackages::BatchMoveLocks
  def initialize(project:, source_targets:, target:)
    @project = project
    @source_targets = source_targets
    @destination = target.lock_record
  end

  # Source locks prevent moving members out after FinishService enumerates them.
  # Ordering every source and target by [class, id] prevents deadlocks between
  # batches with inverse source/target pairs.
  def acquire_lifecycle
    records = @source_targets.uniq.map(&:lock_record) + [@destination]
    ordered = records.compact.uniq { |record| lifecycle_identity(record) }.sort_by { |record| lifecycle_identity(record) }
    acquire_ordered(ordered)
  end

  def acquire_placement(target:, prev_id:)
    return if prev_id.present? && target != Backlogs::Target::InboxId

    suffix = ["backlogs_batch_update_destination", target.list_type, target.list_id].compact.join("_")
    # rubocop:disable-next Lint/EmptyBlock -- transaction-scoped lock outlives this block
    OpenProject::Mutex.with_advisory_lock_transaction(@project, suffix) {}
  end

  def acquire_members(work_packages:, anchor:)
    acquire_ordered((work_packages + [anchor]).compact.uniq.sort_by(&:id))
  end

  def lock_destination_row
    @destination&.lock!
  rescue ActiveRecord::RecordNotFound
    nil
  end

  private

  def lifecycle_identity(record)
    [record.class.name, record.id]
  end

  # Transaction-scoped locks survive these empty blocks. The gem forgets its
  # per-thread lock entry, so inner services may request it again; PostgreSQL
  # grants the transaction its already-held lock without waiting.
  def acquire_ordered(records)
    records.each do |record|
      # rubocop:disable-next Lint/EmptyBlock -- transaction-scoped lock outlives this block
      OpenProject::Mutex.with_advisory_lock_transaction(record) {}
    end
  end
end
