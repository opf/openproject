#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

    SINGLE_THREAD_DEBOUNCE_TIME = 4.seconds.freeze
    MULTI_THREAD_DEBOUNCE_TIME = 5.seconds.freeze
    KEY = :manage_nextcloud_integration_events_job_debounce_happend_at

    queue_with_priority :above_normal

    class << self
      def debounce
        unless debounce_happend_in_current_thread_recently?
          Rails.cache.fetch(KEY, expires_in: MULTI_THREAD_DEBOUNCE_TIME) do
            set(wait: MULTI_THREAD_DEBOUNCE_TIME).perform_later
            RequestStore.store[KEY] = Time.current
          end
        end
      end

      private

      def debounce_happend_in_current_thread_recently?
        timestamp = RequestStore.store[KEY]
        timestamp.present? && (timestamp + SINGLE_THREAD_DEBOUNCE_TIME) > Time.current
      end
    end

    def perform
      lock_obtained = super
      self.class.debounce unless lock_obtained
      lock_obtained
    end
  end
end
