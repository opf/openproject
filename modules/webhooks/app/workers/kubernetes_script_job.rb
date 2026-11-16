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

class KubernetesScriptJob < ApplicationJob
  JOB_TTL_SECONDS = 600
  TOKEN_GRACE_SECONDS = 120
  MOUNT_PATH = "/openproject"

  attr_reader :run

  def perform(run_id, payload_job_class, resource, actor: nil)
    @run = ::Webhooks::KubernetesScriptRun.find_by(id: run_id)
    return unless run

    payload = payload_job_class.constantize.new.payload_for(resource, run.event_name, actor:)
    token = script.issue_access_token!(project: run.project, expires_in: script.timeout_seconds + TOKEN_GRACE_SECONDS)
    run.update!(oauth_access_token_id: token.id)

    status, job = connection.request(:post, "/apis/batch/v1/namespaces/#{namespace}/jobs", body: job_manifest)
    return fail_run!("Creating job failed (#{status}): #{job['message']}") unless status == 201

    status, secret = connection.request(:post, "/api/v1/namespaces/#{namespace}/secrets",
                                        body: secret_manifest(job.dig("metadata", "uid"), payload, token.plaintext_token))
    unless status == 201
      connection.request(:delete, "/apis/batch/v1/namespaces/#{namespace}/jobs/#{job_name}?propagationPolicy=Background")
      return fail_run!("Creating secret failed (#{status}): #{secret['message']}")
    end

    run.update!(status: :running, k8s_job_name: job_name)
    KubernetesScriptStatusJob.set(wait: KubernetesScriptStatusJob::INTERVAL).perform_later(run.id)
  rescue StandardError => e
    fail_run!("#{e.class}: #{e.message}") if run
    raise unless run
  end

  private

  def script = run.kubernetes_script
  def connection = script.kubernetes_connection
  def namespace = connection.effective_namespace
  def job_name = "op-script-#{script.id}-run-#{run.id}"

  def labels
    {
      "app.kubernetes.io/managed-by": "openproject",
      "openproject.org/script-id": script.id.to_s,
      "openproject.org/run-id": run.id.to_s
    }
  end

  def fail_run!(message)
    run.revoke_access_token!
    run.update!(status: :error, message:)
  end

  def job_manifest
    {
      apiVersion: "batch/v1",
      kind: "Job",
      metadata: { name: job_name, labels: },
      spec: {
        backoffLimit: 0,
        activeDeadlineSeconds: script.timeout_seconds,
        ttlSecondsAfterFinished: JOB_TTL_SECONDS,
        template: {
          metadata: { labels: },
          spec: {
            restartPolicy: "Never",
            automountServiceAccountToken: false,
            containers: [container_spec],
            volumes: [{ name: "openproject", secret: { secretName: job_name } }]
          }
        }
      }
    }
  end

  def container_spec
    {
      name: "script",
      image: script.image,
      command: [*Shellwords.split(script.command), "#{MOUNT_PATH}/script"],
      env: [
        { name: "OP_PAYLOAD_FILE", value: "#{MOUNT_PATH}/payload.json" },
        { name: "OP_EVENT", value: run.event_name },
        { name: "OP_PROJECT_ID", value: run.project_id.to_s },
        { name: "OP_SCRIPT_RUN_ID", value: run.id.to_s },
        { name: "OP_API_URL", value: connection.effective_openproject_url },
        { name: "OP_API_TOKEN_FILE", value: "#{MOUNT_PATH}/api_token" },
        *([{ name: "OP_CA_FILE", value: "#{MOUNT_PATH}/ca.crt" }] if connection.openproject_ca_cert.present?)
      ],
      volumeMounts: [{ name: "openproject", mountPath: MOUNT_PATH, readOnly: true }]
    }
  end

  def secret_manifest(job_uid, payload, api_token)
    {
      apiVersion: "v1",
      kind: "Secret",
      type: "Opaque",
      metadata: {
        name: job_name,
        labels:,
        ownerReferences: [{ apiVersion: "batch/v1", kind: "Job", name: job_name, uid: job_uid }]
      },
      stringData: {
        "script" => script.body,
        "payload.json" => payload,
        "api_token" => api_token,
        "ca.crt" => connection.openproject_ca_cert
      }.compact_blank
    }
  end
end
