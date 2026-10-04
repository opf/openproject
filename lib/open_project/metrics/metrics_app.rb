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

# frozen_string_literal: true

require "socket"

##
# Returns metrics about the running server using the Prometheus format.
# This has to be started in the puma master process before forking
# since otherwise it will not yield useful results.
module OpenProject
  module Metrics
    class MetricsApp
      def call(env)
        if metrics_endpoint?(env)
          [200, { "Content-Type" => content_type }, [metrics]]
        else
          [404, { "Content-Type" => content_type }, ["Not found. We only support /metrics."]]
        end
      end

      def collected_puma_metrics
        @collected_puma_metrics ||= {
          backlog: [:puma_request_backlog, "Number of requests waiting to be processed by a puma thread"],
          running: [:puma_running_threads, "Number of puma threads currently running"],
          pool_capacity: [:puma_thread_pool_capacity, "Number of puma threads available at current scale"],
          requests_count: [:puma_requests_count, "The number of requests processed"],
          busy_threads: [
            :puma_busy_threads,
            "Wholistic stat reflecting the overall current state of work to be done and the capacity to do it"
          ]
        }
      end

      def puma_metrics
        metrics = collected_puma_metrics.keys
        values = puma_metric_values metrics
        stats = metrics.zip(values).to_h
        text = +""

        stats.each do |metric, value|
          name, help = collected_puma_metrics[metric]

          text << "# HELP #{name} #{help}\n"
          text << "# TYPE #{name} gauge\n"
          text << "#{name}{hostname=\"#{hostname}\"} #{value}\n\n"
        end

        text
      end

      def puma_metric_values(metrics)
        status = Array(Puma.stats_hash[:worker_status])

        if status.empty? # puma not running in clustered mode
          status = [{ last_status: Puma.stats_hash }]
        end

        status
          .map { |status| get_stats status, metrics }
          .transpose
          .map(&:sum)
      end

      def get_stats(status, metrics)
        stats = Hash(status[:last_status])

        metrics.map { |metric| stats[metric] || 0 }
      end

      def metrics_endpoint?(env)
        env["REQUEST_PATH"] == "/metrics"
      end

      def hostname
        @hostname ||= Socket.gethostname
      end

      def metrics
        puma_metrics
      end

      def content_type
        "text/plain; charset=utf-8"
      end
    end
  end
end
