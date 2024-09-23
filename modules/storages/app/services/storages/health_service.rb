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

module Storages
  class HealthService
    def initialize(storage:)
      @storage = storage
    end

    def healthy
      if @storage.health_status == "healthy"
        @storage.touch(:health_checked_at)
      else
        reason = @storage.health_reason

        @storage.update(health_status: "healthy",
                        health_changed_at: Time.now.utc,
                        health_checked_at: Time.now.utc,
                        health_reason: nil)

        notify_healthy_admin_users(reason)
      end
    end

    def unhealthy(reason:)
      time = Time.now.utc

      if @storage.health_status == "unhealthy"
        if reason_is_same(reason)
          @storage.update(health_checked_at: time)
        else
          @storage.update(health_changed_at: time,
                          health_checked_at: time,
                          health_reason: reason)

          notify_unhealthy_admin_users
        end
      else
        @storage.update(health_status: "unhealthy",
                        health_changed_at: time,
                        health_checked_at: time,
                        health_reason: reason)

        notify_unhealthy_admin_users
      end

      schedule_mail_job(@storage)
    end

    private

    def notify_healthy_admin_users(reason)
      return unless @storage.health_notifications_should_be_sent?

      admin_users.each do |admin|
        ::Storages::StoragesMailer.notify_healthy(admin, @storage, reason).deliver_later
      end
    end

    def notify_unhealthy_admin_users
      return unless @storage.health_notifications_should_be_sent?

      admin_users.each do |admin|
        ::Storages::StoragesMailer.notify_unhealthy(admin, @storage).deliver_later
      end
    end

    def admin_users
      User.where(admin: true)
          .where.not(mail: [nil, ""])
    end

    def schedule_mail_job(storage)
      ::Storages::HealthStatusMailerJob.schedule(storage:)
    end

    def reason_is_same(new_health_reason)
      @storage.health_reason_identifier == ::Storages::Storage.extract_part_from_piped_string(new_health_reason, 0)
    end
  end
end
