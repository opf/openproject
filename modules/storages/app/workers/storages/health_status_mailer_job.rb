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

module Storages
  class HealthStatusMailerJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      total_limit: 2,
      enqueue_limit: 1,
      perform_limit: 1,
      key: -> { "#{self.class.name}-#{arguments.last[:storage].id}" }
    )

    retry_on GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError,
             wait: 5.minutes,
             attempts: 3

    discard_on ActiveJob::DeserializationError

    def perform(storage:)
      return unless storage.health_notifications_should_be_sent?
      return if storage.health_healthy?

      admin_users.each do |admin|
        StoragesMailer.notify_unhealthy(admin, storage).deliver_later
      end

      HealthStatusMailerJob.schedule(storage:)
    end

    class << self
      def schedule(storage:)
        next_run_time = Date.tomorrow.beginning_of_day + 2.hours

        HealthStatusMailerJob.set(wait_until: next_run_time).perform_later(storage:)
      end
    end

    private

    def admin_users
      User.where(admin: true)
          .where.not(mail: [nil, ""])
    end
  end
end
