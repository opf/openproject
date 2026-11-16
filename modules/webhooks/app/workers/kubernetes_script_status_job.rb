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

class KubernetesScriptStatusJob < ApplicationJob
  INTERVAL = 10.seconds
  GRACE_PERIOD = 2.minutes
  LOG_LINES = 200

  attr_reader :run

  def perform(run_id)
    @run = ::Webhooks::KubernetesScriptRun.find_by(id: run_id)
    return unless run&.running?

    status, job = connection.request(:get, "#{jobs_path}/#{run.k8s_job_name}")
    return finish!(:error, "Job no longer exists in the cluster.") if status == 404
    raise "Reading job failed (#{status}): #{job['message']}" unless status == 200

    if job.dig("status", "succeeded").to_i.positive?
      finish!(:succeeded, logs)
    elsif job.dig("status", "failed").to_i.positive?
      finish!(:failed, [failure_reason(job), logs].compact_blank.join("\n\n"))
    elsif run.created_at < deadline
      finish!(:error, "No result within the timeout. #{logs}")
    else
      self.class.set(wait: INTERVAL).perform_later(run.id)
    end
  rescue StandardError => e
    raise unless run

    finish!(:error, "#{e.class}: #{e.message}")
  end

  private

  def connection = run.kubernetes_script.kubernetes_connection
  def namespace = connection.effective_namespace
  def jobs_path = "/apis/batch/v1/namespaces/#{namespace}/jobs"

  def deadline
    (run.kubernetes_script.timeout_seconds.seconds + GRACE_PERIOD).ago
  end

  def finish!(status, message)
    run.revoke_access_token!
    run.update!(status:, message:)
  end

  def failure_reason(job)
    Array(job.dig("status", "conditions"))
      .select { it["status"] == "True" && it["type"] == "Failed" }
      .map { "#{it['reason']}: #{it['message']}" }
      .first
  end

  def logs
    selector = CGI.escape("job-name=#{run.k8s_job_name}")
    status, pods = connection.request(:get, "/api/v1/namespaces/#{namespace}/pods?labelSelector=#{selector}")
    pod = Array(pods["items"]).first if status == 200
    return "" unless pod

    path = "/api/v1/namespaces/#{namespace}/pods/#{pod.dig('metadata', 'name')}/log?tailLines=#{LOG_LINES}"
    status, body = connection.request(:get, path, raw: true)
    status == 200 ? body : ""
  end
end
