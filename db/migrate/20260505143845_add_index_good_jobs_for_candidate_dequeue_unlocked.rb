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

class AddIndexGoodJobsForCandidateDequeueUnlocked < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :good_jobs, %i[priority scheduled_at id],
              name: :index_good_jobs_for_candidate_dequeue_unlocked,
              order: { priority: "ASC NULLS LAST", scheduled_at: :asc, id: :asc },
              where: "finished_at IS NULL AND locked_by_id IS NULL",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
