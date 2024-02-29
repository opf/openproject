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
  module Health
    class HealthService
      def initialize(storage:)
        @storage = storage
      end

      def healthy
        was_unhealthy = @storage.health_unhealthy?
        reason = @storage.health_reason

        @storage.mark_as_healthy

        admin_users.each do |admin|
          ::Storages::StoragesMailer.notify_healthy(admin, @storage, reason).deliver_now if was_unhealthy
        end
      end

      def unhealthy(reason:)
        last_reason = @storage.health_reason
        @storage.mark_as_unhealthy(reason:)

        if @storage.health_reason != last_reason
          admin_users.each do |admin|
            ::Storages::StoragesMailer.notify_unhealthy(admin, @storage).deliver_now
          end
        end

        schedule_mail_job(@storage) unless mail_job_exists?
      end

      private

      def admin_users
        User.where(admin: true)
            .where.not(mail: [nil, ''])
      end

      def schedule_mail_job(storage)
        ::Storages::HealthStatusMailerJob.schedule(admins: admin_users, storage:)
      end

      def mail_job_exists?
        Delayed::Job.where('handler LIKE ?', "%job_class: Storages::HealthStatusMailerJob%").any?
      end
    end
  end
end
