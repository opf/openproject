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

class Labels::CleanupUnusedInlineJob < ApplicationJob
  include JobConcurrency

  GRACE_PERIOD = 15.minutes
  MIN_WAIT = 1.minute

  queue_with_priority :low
  good_job_control_concurrency_with(enqueue_limit: 1, key: name)

  def self.perform_after_grace(from: Time.current)
    set(wait_until: [from + GRACE_PERIOD, MIN_WAIT.from_now].max).perform_later
  end

  def perform
    Label.transaction do
      ids = candidate_ids
      Label.never_used.where(id: ids).delete_all if ids.any?
    end

    schedule_next_run
  end

  private

  def schedule_next_run
    oldest = Label.created_inline.never_used.minimum(:updated_at)
    self.class.perform_after_grace(from: oldest) if oldest
  end

  def candidate_ids
    candidates.lock("FOR UPDATE SKIP LOCKED").pluck(:id)
  end

  def candidates
    Label.created_inline.never_used.where(updated_at: ..GRACE_PERIOD.ago)
  end
end
