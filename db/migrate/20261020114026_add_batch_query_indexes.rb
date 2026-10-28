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

class AddBatchQueryIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :good_job_batches, :finished_at,
              name: :index_good_job_batches_on_finished_at,
              where: "finished_at IS NOT NULL",
              algorithm: :concurrently,
              if_not_exists: true
    add_index :good_job_batches, %i[created_at id],
              name: :index_good_job_batches_on_created_at_and_id,
              order: { created_at: :desc, id: :desc },
              algorithm: :concurrently,
              if_not_exists: true
    add_index :good_jobs, :batch_id,
              name: :index_good_jobs_on_batch_id_unfinished,
              where: "batch_id IS NOT NULL AND finished_at IS NULL",
              algorithm: :concurrently,
              if_not_exists: true
    add_index :good_jobs, :batch_callback_id,
              name: :index_good_jobs_on_batch_callback_id_unfinished,
              where: "batch_callback_id IS NOT NULL AND finished_at IS NULL",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
