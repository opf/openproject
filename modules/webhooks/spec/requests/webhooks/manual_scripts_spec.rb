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

RSpec.describe "Manual script runs", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %w[work_package_tracking]) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages run_manual_scripts] })
  end
  shared_let(:script) do
    connection = Webhooks::KubernetesConnection.create!(name: "Cluster", auth_mode: :in_cluster)
    Webhooks::KubernetesScript.create!(
      name: "Echo", kubernetes_connection: connection, image: "python:3.13-slim", command: "python",
      body: "print('hi')", timeout_seconds: 60, manual: true,
      input_schema: {
        "type" => "object",
        "required" => ["summary"],
        "properties" => {
          "summary" => { "type" => "string" },
          "count" => { "type" => "integer" },
          "tasks" => { "type" => "array", "items" => { "type" => "object",
                                                       "properties" => { "title" => { "type" => "string" } } } }
        }
      }
    ).tap { it.project_scripts.create!(project:) }
  end

  current_user { user }

  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  describe "POST refresh" do
    it "applies Add and keeps the entered values" do
      post refresh_work_package_manual_scripts_path(work_package, script_id: script.id),
           params: { input: { summary: "Typed", tasks: { "0" => { title: "First" } } }, _operation: "add:tasks" },
           headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('method="morph"')
      expect(response.body).to include('value="Typed"')
      expect(response.body).to include('name="input[tasks][1][title]"')
    end
  end

  describe "POST create" do
    before { allow(KubernetesScriptJob).to receive(:perform_later) }

    it "rejects invalid input and shows the errors in the form" do
      expect do
        post work_package_manual_scripts_path(work_package, script_id: script.id),
             params: { input: { count: "many" } }, headers: turbo_headers
      end.not_to change(Webhooks::KubernetesScriptRun, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("This field is required.").and include("The value must be a whole number.")
    end

    it "starts a run with the typed input" do
      post work_package_manual_scripts_path(work_package, script_id: script.id),
           params: { input: { summary: "Deploy", count: "3", tasks: { "0" => { title: "First" } } } },
           headers: turbo_headers

      run = Webhooks::KubernetesScriptRun.last
      expect(response).to have_http_status(:ok)
      expect(run).to have_attributes(trigger: "manual", triggered_by: user, work_package:,
                                     input: { "summary" => "Deploy", "count" => 3, "tasks" => [{ "title" => "First" }] })
      expect(KubernetesScriptJob).to have_received(:perform_later).with(run.id, anything, work_package, actor: user)
    end
  end

  context "without the permission to run manual scripts" do
    current_user { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    it "refuses to refresh the form" do
      post refresh_work_package_manual_scripts_path(work_package, script_id: script.id), headers: turbo_headers

      expect(response).to have_http_status(:forbidden)
    end
  end
end
