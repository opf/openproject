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
require "rack/test"

RSpec.describe "APIv3 test management ingest end to end" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper
  include FileHelpers

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:uploader) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases view_test_runs upload_test_results add_test_cases edit_test_cases]
           })
  end

  let(:results_path) { api_v3_paths.project_test_management_automation_results(project.id) }
  let(:junit) do
    File.read(File.expand_path("../../../../fixtures/files/test_management/junit-report.xml", __dir__)).gsub("__CASE_ID__", "0")
  end
  let!(:creates) { create(:tm_test_case, project:, automation_reference: "UsersApiTest#creates a user") }
  let!(:rejects) { create(:tm_test_case, project:, automation_reference: "UsersApiTest#rejects duplicate e-mail") }

  before { login_as(uploader) }

  def json = JSON.parse(last_response.body)

  def upload(content: junit, **metadata)
    post results_path, { report: mock_uploaded_file(name: "junit.xml", content_type: "application/xml", content:),
                         metadata: metadata.to_json }
  end

  def run = TestManagement::TestRun.find(json["run"]["id"])

  it "creates a run for a JUnit upload with an externalRef" do
    upload(externalRef: "ci:1")

    expect(last_response).to have_http_status(201)
    expect(json).to include("createdRun" => true, "replay" => false)
    expect(json["import"]).to include("parsedCount" => 4, "matchedCount" => 2, "unmatchedCount" => 2)
    expect(run).to have_attributes(source: "automation", external_ref: "ci:1", state: "in_progress")
    expect(run.run_cases.to_h { [it.test_case_id, it.status] }).to eq(creates.id => "passed", rejects.id => "failed")
  end

  it "replays an identical upload without duplicating anything" do
    upload(externalRef: "ci:1")
    run_id = json["run"]["id"]

    upload(externalRef: "ci:1")

    expect(last_response).to have_http_status(200)
    expect(json).to include("createdRun" => false, "replay" => true)
    expect(json["run"]["id"]).to eq(run_id)
    expect(TestManagement::AutomationImport.where(test_run_id: run_id).count).to eq(1)
    expect(TestManagement::TestResult.where(run_case_id: TestManagement::TestRunCase.where(test_run_id: run_id)).count).to eq(2)
    expect(TestManagement::TestRun.where(project_id: project.id).count).to eq(1)
  end

  it "adds the next iteration with mode new_iteration" do
    upload(mode: "new_iteration", targetRun: "Smoke", externalRef: "ci:1")
    expect(json["iteration"]).to include("number" => 1)

    upload(mode: "new_iteration", targetRun: "Smoke", externalRef: "ci:2")

    expect(last_response).to have_http_status(200)
    expect(json).to include("createdRun" => false, "createdIteration" => true)
    expect(json["iteration"]).to include("number" => 2)
    expect(TestManagement::TestRun.where(project_id: project.id).count).to eq(1)
  end

  it "completes the run with closeRun" do
    upload(externalRef: "ci:1", closeRun: true)

    expect(run).to have_attributes(state: "completed", completion_source: "automation")
  end

  it "creates missing cases in a folder named after the file and writes the reference" do
    upload(externalRef: "ci:1", createMissing: true)

    created = project.tm_test_cases.find_by!(automation_reference: "UsersApiTest#paginates users")
    expect(created).to have_attributes(automated: true, author: uploader)
    expect(created.suite.name).to eq("UsersApiTest")
    expect(json["import"]).to include("createdCasesCount" => 2, "unmatchedCount" => 0)
  end

  it "keeps ingesting while CI is switched off for the project" do
    create(:tm_project_setting, project:, options: { "enable_ci" => false })

    upload(externalRef: "ci:1")

    expect(last_response).to have_http_status(201)
  end

  it "is forbidden without the upload permission" do
    login_as(create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] }))

    upload

    expect(last_response).to have_http_status(403)
  end
end
