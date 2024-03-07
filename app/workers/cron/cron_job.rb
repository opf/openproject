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

module Cron
  class CronJob < ApplicationJob
    class_attribute :cron_expression

    # List of registered jobs, requires eager load in dev(!)
    class_attribute :registered_jobs, default: []

    include ScheduledJob

    class << self
      ##
      # Register new job class(es)
      def register!(*job_classes)
        Array(job_classes).each do |clz|
          raise ArgumentError, "Needs to be subclass of ::Cron::CronJob" unless clz.ancestors.include?(self)

          registered_jobs << clz
        end
      end

      def schedule_registered_jobs!
        registered_jobs.each do |job_class|
          job_class.ensure_scheduled!
        end
      end

      ##
      # Ensure the job is scheduled unless it is already
      def ensure_scheduled!
        # Ensure scheduled only once
        return if scheduled?

        Rails.logger.info { "Scheduling #{name} recurrent background job." }
        set(cron: cron_expression).perform_later
      end

      ##
      # Remove the scheduled job, if any
      def remove
        delayed_job&.destroy
      end

      def delayed_job
        delayed_job_query.first
      end
    end
  end
end
