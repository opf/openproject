#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Storages
  class ManageNextcloudIntegrationEventsJob < ApplicationJob
    include ManageNextcloudIntegrationJobMixin

    THREAD_DEBOUNCE_TIME = 4.seconds.freeze
    JOB_DEBOUNCE_TIME = 5.seconds.freeze
    THREAD_KEY = :manage_nextcloud_integration_events_job_debounce_happend_at

    queue_with_priority :above_normal

    def self.debounce
      last_debounce_happend_at = RequestStore.store[THREAD_KEY]
      if last_debounce_happend_at.blank? || Time.current > (last_debounce_happend_at + THREAD_DEBOUNCE_TIME)
        count = Delayed::Job
                  .where("handler LIKE ?", "%job_class: #{self}%")
                  .where(locked_at: nil)
                  .where('run_at <= ?', JOB_DEBOUNCE_TIME.from_now)
                  .delete_all
        Rails.logger.info("deleted: #{count} jobs")
        RequestStore.store[THREAD_KEY] = Time.current
        set(wait: JOB_DEBOUNCE_TIME).perform_later
      end
    end

    def perform
      lock_obtained = super
      self.class.debounce unless lock_obtained
      lock_obtained
    end
  end
end
