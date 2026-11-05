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

RSpec.describe "APIv3 test management cases" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:editor) do
    create(:user, member_with_permissions: { project => %i[view_test_cases add_test_cases edit_test_cases delete_test_cases] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }
  shared_let(:outsider) { create(:user) }

  let(:current) { editor }
  let(:collection_path) { api_v3_paths.project_test_management_cases(project.id) }

  before { login_as(current) }

  def json = JSON.parse(last_response.body)

  def send_json(verb, path, body = {})
    public_send(verb, path, body.to_json, { "CONTENT_TYPE" => "application/json" })
  end

  describe "GET collection" do
    let!(:folder) { create(:tm_suite, project:) }
    let!(:ready) { create(:tm_test_case, project:, suite: folder, title: "Reset password", status: "ready", priority: "high") }
    let!(:draft) { create(:tm_test_case, project:, title: "Sign in", status: "draft", priority: "low", automated: true) }

    def ids = json["_embedded"]["elements"].pluck("id")

    it "lists the cases of the project only" do
      create(:tm_test_case)

      get collection_path

      expect(last_response).to have_http_status(200)
      expect(ids).to contain_exactly(ready.id, draft.id)
    end

    it "filters by folder, search, status, priority and automation" do
      get "#{collection_path}?folderId=#{folder.id}"
      expect(ids).to eq([ready.id])

      get "#{collection_path}?search=sign"
      expect(ids).to eq([draft.id])

      get "#{collection_path}?status=draft&priority=low"
      expect(ids).to eq([draft.id])

      get "#{collection_path}?automated=true"
      expect(ids).to eq([draft.id])
    end

    it "paginates" do
      create_list(:tm_test_case, 3, project:)

      get "#{collection_path}?pageSize=2&offset=2"

      expect(json).to include("total" => 5, "count" => 2, "pageSize" => 2, "offset" => 2)
    end

    it "is not found for outsiders" do
      login_as(outsider)

      get collection_path

      expect(last_response).to have_http_status(404)
    end
  end

  describe "POST collection" do
    it "creates a case with steps (201)" do
      send_json(:post, collection_path, { title: "Pay", priority: "high", status: "draft",
                                          steps: [{ action: "Open cart", expectedResult: "Cart shown" },
                                                  { action: "Pay", expectedResult: "Receipt" }] })

      expect(last_response).to have_http_status(201)
      expect(json).to include("_type" => "TestManagementCase", "title" => "Pay", "priority" => "high", "lockVersion" => 0)
      expect(json["steps"].pluck("position", "action")).to eq([[0, "Open cart"], [1, "Pay"]])
      expect(TestManagement::TestCase.find(json["id"]).author).to eq(editor)
    end

    it "answers 422 for invalid values" do
      send_json(:post, collection_path, { title: "" })
      expect(last_response).to have_http_status(422)

      send_json(:post, collection_path, { title: "Bad", priority: "urgent" })
      expect(last_response).to have_http_status(422)

      send_json(:post, collection_path, { title: "Steps", steps: "nope" })
      expect(last_response).to have_http_status(422)
    end

    it "is forbidden without add_test_cases" do
      login_as(viewer)

      send_json(:post, collection_path, { title: "Nope" })

      expect(last_response).to have_http_status(403)
      expect(TestManagement::TestCase.count).to eq(0)
    end
  end

  describe "single case" do
    let!(:test_case) { create(:tm_test_case, :with_steps, project:, title: "Before") }
    let(:path) { api_v3_paths.test_management_case(test_case.id) }

    it "renders the case" do
      get path

      expect(last_response).to have_http_status(200)
      expect(json).to include("id" => test_case.id, "title" => "Before", "formattedId" => test_case.formatted_id)
      expect(json["steps"].size).to eq(2)
    end

    it "updates attributes and replaces the steps" do
      send_json(:patch, path, { title: "After", lockVersion: test_case.lock_version,
                                steps: [{ action: "Only step", expectedResult: "Done" }] })

      expect(last_response).to have_http_status(200)
      expect(json).to include("title" => "After", "lockVersion" => test_case.lock_version + 1)
      expect(test_case.reload.steps.map(&:action)).to eq(["Only step"])
      expect(test_case.updated_by).to eq(editor)
    end

    it "keeps the steps when none are sent" do
      send_json(:patch, path, { title: "After", lockVersion: test_case.lock_version })

      expect(test_case.reload.steps.count).to eq(2)
    end

    it "answers 409 for a stale lockVersion and changes nothing" do
      send_json(:patch, path, { title: "First", lockVersion: test_case.lock_version })
      expect(last_response).to have_http_status(200)

      send_json(:patch, path, { title: "Second", lockVersion: test_case.lock_version })

      expect(last_response).to have_http_status(409)
      expect(test_case.reload.title).to eq("First")
    end

    it "answers 422 without a lockVersion" do
      send_json(:patch, path, { title: "After" })

      expect(last_response).to have_http_status(422)
      expect(test_case.reload.title).to eq("Before")
    end

    it "deletes the case (204)" do
      send_json(:delete, path)

      expect(last_response).to have_http_status(204)
      expect(TestManagement::TestCase.exists?(test_case.id)).to be(false)
    end

    it "is forbidden to change for viewers and not found for outsiders" do
      login_as(viewer)
      send_json(:patch, path, { title: "X", lockVersion: test_case.lock_version })
      expect(last_response).to have_http_status(403)
      send_json(:delete, path)
      expect(last_response).to have_http_status(403)

      login_as(outsider)
      get path
      expect(last_response).to have_http_status(404)
      expect(test_case.reload.title).to eq("Before")
    end
  end
end
