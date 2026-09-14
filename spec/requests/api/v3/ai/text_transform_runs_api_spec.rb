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

require "spec_helper"
require "rack/test"

RSpec.describe API::V3::AI::TextTransformRunsAPI,
               with_flag: { ai_text_transform_actions: true },
               with_settings: { ai_text_transform_actions_enabled: true } do
  include API::V3::Utilities::PathHelper

  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:work_package) { create(:work_package, project:, type:) }
  shared_let(:action) { create(:ai_text_transform_action) }

  let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages add_work_packages] })
  end
  let(:gateway) { AI::TextTransforms::FakeGateway.new }
  let(:body) { { actionId: action.id, content: "Login page dont work." } }

  before do
    allow(AI::TextTransforms::Gateway).to receive(:build).and_return(gateway)
    login_as user
  end

  def post_run(payload)
    post api_v3_paths.ai_text_transform_runs, payload.to_json, "CONTENT_TYPE" => "application/json"
  end

  def post_cancel(run)
    post api_v3_paths.ai_text_transform_run_cancel(run.uuid), "", "CONTENT_TYPE" => "application/json"
  end

  describe "POST /api/v3/ai_text_transform_runs" do
    it "creates a run without context and enqueues the job" do
      expect { post_run(body) }.to have_enqueued_job(AI::TextTransformJob)

      expect(last_response).to have_http_status(:accepted)
      run = AI::TextTransformRun.last
      expect(run.user).to eq(user)
      expect(run.input).to eq(body[:content])
      expect(run.system_prompt).to include(action.prompt)
      expect(last_response.body).to be_json_eql("AITextTransformRun".to_json).at_path("_type")
      expect(last_response.body).to be_json_eql(run.uuid.to_json).at_path("id")
      expect(last_response.body).to be_json_eql("queued".to_json).at_path("status")
      expect(last_response.body).to be_json_eql(run.system_prompt.to_json).at_path("systemPrompt")
      expect(last_response.body).to have_json_path("_links/cancel")
    end

    it "creates a run for a work package the user may edit" do
      post_run(body.merge(workPackageId: work_package.id))

      expect(last_response).to have_http_status(:accepted)
      expect(AI::TextTransformRun.last.input).to eq(body[:content])
    end

    it "creates a run for a new work package in a project and injects the type template" do
      type.default_variant.update!(default_work_package_description: "## Steps to reproduce")
      action.update!(usage_scope: "all_work_package_types", injects_type_template: true)
      post_run(body.merge(projectId: project.id, typeId: type.id))

      expect(last_response).to have_http_status(:accepted)
      expect(AI::TextTransformRun.last.system_prompt).to include("## Steps to reproduce")
    end

    it "answers 422 when the action is not available" do
      action.update!(active: false)
      post_run(body)

      expect(last_response).to have_http_status(:unprocessable_entity)
      expect(last_response.body)
        .to be_json_eql("#{I18n.t('api_v3.errors.ai_text_transform.action_not_available')} (action_inactive)".to_json)
        .at_path("message")
    end

    it "answers 422 for an unknown action" do
      post_run(body.merge(actionId: 0))

      expect(last_response).to have_http_status(:unprocessable_entity)
    end

    it "answers 422 for blank content" do
      post_run(body.merge(content: ""))

      expect(last_response).to have_http_status(:unprocessable_entity)
    end

    it "answers 400 when work package and project are both given" do
      post_run(body.merge(workPackageId: work_package.id, projectId: project.id, typeId: 1))

      expect(last_response).to have_http_status(:bad_request)
    end

    it "answers 403 without edit permission on the work package" do
      user = create(:user, member_with_permissions: { project => %i[view_work_packages] })
      login_as user
      post_run(body.merge(workPackageId: work_package.id))

      expect(last_response).to have_http_status(:forbidden)
    end

    it "answers 404 for an invisible work package" do
      login_as create(:user)
      post_run(body.merge(workPackageId: work_package.id))

      expect(last_response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v3/ai_text_transform_runs/:uuid" do
    let(:run) { create(:ai_text_transform_run, user:, action:) }

    before do
      run.append_event("status", status: "running")
      run.append_event("text_delta", delta: "The ")
      run.append_event("text_delta", delta: "login")
    end

    it "returns the events after the cursor" do
      get "#{api_v3_paths.ai_text_transform_run(run.uuid)}?after=1"

      expect(last_response).to have_http_status(:ok)
      expect(last_response.body).to have_json_size(2).at_path("events")
      expect(last_response.body).to be_json_eql(2.to_json).at_path("events/0/seq")
      expect(last_response.body).to be_json_eql("login".to_json).at_path("events/1/payload/delta")
    end

    it "returns everything without a cursor" do
      get api_v3_paths.ai_text_transform_run(run.uuid)

      expect(last_response.body).to have_json_size(3).at_path("events")
    end

    it "hides the cancel link on a terminal run" do
      run.finish!("succeeded")
      get api_v3_paths.ai_text_transform_run(run.uuid)

      expect(last_response.body).not_to have_json_path("_links/cancel")
    end

    it "answers 404 for another user's run, admins included" do
      login_as create(:admin)
      get api_v3_paths.ai_text_transform_run(run.uuid)

      expect(last_response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v3/ai_text_transform_runs/:uuid/cancel" do
    let(:run) { create(:ai_text_transform_run, user:, action:) }

    it "requests cancellation idempotently" do
      2.times { post_cancel(run) }

      expect(last_response).to have_http_status(:no_content)
      expect(run.reload.cancel_requested).to be(true)
    end

    it "leaves a terminal run untouched" do
      run.finish!("succeeded")
      post_cancel(run)

      expect(last_response).to have_http_status(:no_content)
      expect(run.reload.cancel_requested).to be(false)
    end

    it "answers 404 for another user's run" do
      login_as create(:user)
      post_cancel(run)

      expect(last_response).to have_http_status(:not_found)
    end
  end
end
