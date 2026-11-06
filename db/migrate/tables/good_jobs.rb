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

require_relative "base"

class Tables::GoodJobs < Tables::Base
  def self.table(migration) # rubocop:disable Metrics/AbcSize
    create_table migration, id: :uuid do |t|
      t.text :queue_name
      t.integer :priority
      t.jsonb :serialized_params
      t.datetime :scheduled_at
      t.datetime :performed_at
      t.datetime :finished_at
      t.text :error
      t.timestamps
      t.uuid :active_job_id
      t.text :concurrency_key
      t.text :cron_key
      t.uuid :retried_good_job_id
      t.datetime :cron_at
      t.uuid :batch_id
      t.uuid :batch_callback_id
      t.boolean :is_discrete # rubocop:disable Rails/ThreeStateBooleanColumn
      t.integer :executions_count
      t.text :job_class
      t.integer :error_event, limit: 2
      t.text :labels, array: true
      t.uuid :locked_by_id
      t.datetime :locked_at

      t.index :scheduled_at,
              where: "(finished_at IS NULL)",
              name: :index_good_jobs_on_scheduled_at
      t.index %i[queue_name scheduled_at],
              where: "(finished_at IS NULL)",
              name: :index_good_jobs_on_queue_name_and_scheduled_at
      t.index %i[active_job_id created_at],
              name: :index_good_jobs_on_active_job_id_and_created_at
      t.index :concurrency_key,
              where: "(finished_at IS NULL)",
              name: :index_good_jobs_on_concurrency_key_when_unfinished
      t.index [:finished_at],
              where: "retried_good_job_id IS NULL AND finished_at IS NOT NULL",
              name: :index_good_jobs_jobs_on_finished_at
      t.index %i[priority created_at],
              order: { priority: "DESC NULLS LAST", created_at: :asc },
              where: "finished_at IS NULL",
              name: :index_good_jobs_jobs_on_priority_created_at_when_unfinished
      t.index :batch_id, where: "batch_id IS NOT NULL"
      t.index :batch_callback_id, where: "batch_callback_id IS NOT NULL"
      t.index %i[cron_key created_at],
              where: "(cron_key IS NOT NULL)",
              name: :index_good_jobs_on_cron_key_and_created_at_cond
      t.index %i[cron_key cron_at],
              where: "(cron_key IS NOT NULL)",
              unique: true,
              name: :index_good_jobs_on_cron_key_and_cron_at_cond
      t.index :labels,
              using: :gin,
              where: "(labels IS NOT NULL)",
              name: :index_good_jobs_on_labels
      t.index %i[priority created_at],
              order: { priority: "ASC NULLS LAST", created_at: :asc },
              where: "finished_at IS NULL",
              name: :index_good_job_jobs_for_candidate_lookup
      t.index %i[priority scheduled_at],
              order: { priority: "ASC NULLS LAST", scheduled_at: :asc },
              where: "finished_at IS NULL AND locked_by_id IS NULL",
              name: :index_good_jobs_on_priority_scheduled_at_unfinished_unlocked
      t.index :locked_by_id,
              where: "locked_by_id IS NOT NULL",
              name: :index_good_jobs_on_locked_by_id
    end
  end
end
