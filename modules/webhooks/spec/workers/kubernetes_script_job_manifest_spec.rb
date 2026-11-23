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

require "spec_helper"

RSpec.describe KubernetesScriptJob, "manifests" do
  let(:connection) { Webhooks::KubernetesConnection.create!(name: "Cluster", auth_mode: :in_cluster, namespace: "ns") }
  let(:script) do
    Webhooks::KubernetesScript.create!(name: "Env", kubernetes_connection: connection, image: "alpine", command: "sh",
                                       body: "env", timeout_seconds: 60, environment_variables: { "API_KEY" => "secret" })
  end
  let(:run) { Webhooks::KubernetesScriptRun.new(id: 7, kubernetes_script: script, trigger: :manual, event_name: "x") }
  let(:job) { described_class.new.tap { it.instance_variable_set(:@run, run) } }

  it "passes the environment variables through the run's secret without mounting them", :aggregate_failures do
    secret = job.send(:secret_manifest, "uid", "{}", "token")
    pod = job.send(:job_manifest).dig(:spec, :template, :spec)
    env = pod[:containers].first[:env]

    expect(secret[:stringData]).to include("env.API_KEY" => "secret", "script" => "env")
    expect(env).to include(name: "API_KEY",
                           valueFrom: { secretKeyRef: { name: "op-script-#{script.id}-run-7", key: "env.API_KEY" } })
    expect(env.to_s).not_to include("secret\"")
    expect(pod[:volumes].first.dig(:secret, :items).pluck(:key)).to eq(%w[script payload.json api_token])
  end
end
