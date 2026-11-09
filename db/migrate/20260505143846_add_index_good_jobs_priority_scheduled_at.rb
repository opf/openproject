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

class AddIndexGoodJobsPriorityScheduledAt < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        # Ensure this incremental update migration is idempotent
        # with monolithic install migration.
        return if connection.index_name_exists?(:good_jobs, "index_good_jobs_on_priority_scheduled_at_unfinished") &&
                  connection.index_name_exists?(:good_jobs, "index_good_jobs_on_queue_name_priority_scheduled_at_unfinished")
      end
    end

    add_index :good_jobs, %i[priority scheduled_at id],
              where: "finished_at IS NULL", name: "index_good_jobs_on_priority_scheduled_at_unfinished",
              algorithm: :concurrently
    add_index :good_jobs, %i[queue_name scheduled_at id],
              where: "finished_at IS NULL", name: "index_good_jobs_on_queue_name_priority_scheduled_at_unfinished",
              algorithm: :concurrently
  end
end
