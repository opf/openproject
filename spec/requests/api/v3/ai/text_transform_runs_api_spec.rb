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
  shared_let(:action) { create(:ai_text_transform_action, prompt: "Fix grammar only.") }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages add_work_packages] })
  end

  let(:gateway) { AI::TextTransforms::FakeGateway.new }
  let(:current_user) { user }
  let(:body) { { actionId: action.id, content: "Login page dont work." } }

  before do
    allow(AI::TextTransforms::Gateway).to receive(:build).and_return(gateway)
    login_as current_user
  end

  def post_run(payload)
    post api_v3_paths.ai_text_transform_runs, payload.to_json, "CONTENT_TYPE" => "application/json"
  end

  def post_cancel(run)
    post api_v3_paths.ai_text_transform_run_cancel(run.uuid), "", "CONTENT_TYPE" => "application/json"
  end

  shared_examples "action not available" do |reason|
    it "answers 422 with the reason and creates nothing" do
      expect(last_response).to have_http_status(:unprocessable_entity)
      expect(last_response.body)
        .to be_json_eql("urn:openproject-org:api:v3:errors:UnprocessableContent".to_json).at_path("errorIdentifier")
      expect(last_response.body)
        .to be_json_eql("#{I18n.t('api_v3.errors.ai_text_transform.action_not_available')} (#{reason})".to_json)
        .at_path("message")
      expect(AI::TextTransformRun.count).to eq(0)
    end
  end

  describe "POST /api/v3/ai_text_transform_runs" do
    context "without a context" do
      it "creates a queued run for the current user and enqueues the job" do
        expect { post_run(body) }.to have_enqueued_job(AI::TextTransformJob)

        run = AI::TextTransformRun.sole
        expect(run).to have_attributes(user:, action:, input: body[:content], status: "queued")
        expect(run.system_prompt).to eq("#{AI::TextTransforms::Prompt::SCAFFOLD}\n\nFix grammar only.")

        expect(last_response).to have_http_status(:accepted)
        expect(last_response.body).to be_json_eql("AITextTransformRun".to_json).at_path("_type")
        expect(last_response.body).to be_json_eql(run.uuid.to_json).at_path("id")
        expect(last_response.body).to be_json_eql("queued".to_json).at_path("status")
        expect(last_response.body).to be_json_eql([].to_json).at_path("events")
        expect(last_response.body)
          .to be_json_eql(api_v3_paths.ai_text_transform_run(run.uuid).to_json).at_path("_links/self/href")
        expect(last_response.body)
          .to be_json_eql(api_v3_paths.ai_text_transform_run_cancel(run.uuid).to_json).at_path("_links/cancel/href")
        expect(last_response.body).not_to have_json_path("systemPrompt")
      end
    end

    context "with a work package the user may edit" do
      before { post_run(body.merge(workPackageId: work_package.id)) }

      it "creates the run" do
        expect(last_response).to have_http_status(:accepted)
        expect(AI::TextTransformRun.sole).to have_attributes(user:, input: body[:content])
      end
    end

    context "with a project and a type" do
      before do
        type.default_variant.update!(default_work_package_description: "## Steps to reproduce")
        action.update!(usage_scope: "all_work_package_types", injects_type_template: true)

        post_run(body.merge(projectId: project.id, typeId: type.id))
      end

      it "injects the type template into the stored prompt" do
        expect(last_response).to have_http_status(:accepted)
        expect(AI::TextTransformRun.sole.system_prompt)
          .to end_with("\n\n#{AI::TextTransforms::Prompt::TEMPLATE_INTRO}\n## Steps to reproduce")
      end
    end

    context "with an inactive action" do
      before do
        action.update!(active: false)
        post_run(body)
      end

      it_behaves_like "action not available", :action_inactive
    end

    context "with an unknown action" do
      before { post_run(body.merge(actionId: 0)) }

      it_behaves_like "action not available", :unknown_action
    end

    context "with a type-scoped action and no context" do
      before do
        action.update!(usage_scope: "all_work_package_types")
        post_run(body)
      end

      it_behaves_like "action not available", :context_required
    end

    context "when the assistant is disabled", with_settings: { ai_text_transform_actions_enabled: false } do
      before { post_run(body) }

      it_behaves_like "action not available", :assistant_disabled
    end

    context "with blank content" do
      before { post_run(body.merge(content: "")) }

      it "answers 422 with the model error" do
        expect(last_response).to have_http_status(:unprocessable_entity)
        expect(last_response.body).to be_json_eql("Input can't be blank.".to_json).at_path("message")
        expect(AI::TextTransformRun.count).to eq(0)
      end
    end

    context "with a work package and a project" do
      before { post_run(body.merge(workPackageId: work_package.id, projectId: project.id, typeId: type.id)) }

      it "answers 400" do
        expect(last_response).to have_http_status(:bad_request)
      end
    end

    context "with a project but no type" do
      before { post_run(body.merge(projectId: project.id)) }

      it "answers 400" do
        expect(last_response).to have_http_status(:bad_request)
      end
    end

    context "without edit permission on the work package" do
      let(:current_user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

      before { post_run(body.merge(workPackageId: work_package.id)) }

      it_behaves_like "unauthorized access"
    end

    context "with an invisible work package" do
      let(:current_user) { create(:user) }

      before { post_run(body.merge(workPackageId: work_package.id)) }

      it_behaves_like "not found", I18n.t("api_v3.errors.not_found.work_package")
    end

    context "without add permission in the project" do
      let(:current_user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

      before { post_run(body.merge(projectId: project.id, typeId: type.id)) }

      it_behaves_like "unauthorized access"
    end

    context "with a type not enabled in the project" do
      before { post_run(body.merge(projectId: project.id, typeId: create(:type).id)) }

      it_behaves_like "not found"
    end

    context "when not logged in" do
      let(:current_user) { User.anonymous }

      before { post_run(body) }

      it_behaves_like "forbidden response based on login_required"
    end
  end

  describe "GET /api/v3/ai_text_transform_runs/:uuid" do
    let(:run) { create(:ai_text_transform_run, user:, action:) }

    before do
      run.append_event("status", status: "running")
      run.append_event("text_delta", delta: "The ")
      run.append_event("text_delta", delta: "login")
    end

    context "with a cursor" do
      before { get "#{api_v3_paths.ai_text_transform_run(run.uuid)}?after=1" }

      it "returns only the events after the cursor" do
        expect(last_response).to have_http_status(:ok)
        expect(last_response.body).to be_json_eql("AITextTransformRun".to_json).at_path("_type")
        expect(last_response.body).to be_json_eql(run.uuid.to_json).at_path("id")
        expect(last_response.body).to be_json_eql(
          [
            { seq: 2, kind: "text_delta", payload: { delta: "The " } },
            { seq: 3, kind: "text_delta", payload: { delta: "login" } }
          ].to_json
        ).at_path("events")
      end
    end

    context "without a cursor" do
      before { get api_v3_paths.ai_text_transform_run(run.uuid) }

      it "returns every event" do
        expect(last_response).to have_http_status(:ok)
        expect(last_response.body).to have_json_size(3).at_path("events")
        expect(last_response.body).to be_json_eql({ status: "running" }.to_json).at_path("events/0/payload")
        expect(last_response.body).to have_json_path("_links/cancel")
      end
    end

    context "with a negative cursor" do
      before { get "#{api_v3_paths.ai_text_transform_run(run.uuid)}?after=-1" }

      it "answers 400" do
        expect(last_response).to have_http_status(:bad_request)
      end
    end

    context "with a terminal run" do
      before do
        run.finish!("succeeded")
        get api_v3_paths.ai_text_transform_run(run.uuid)
      end

      it "hides the cancel link" do
        expect(last_response).to have_http_status(:ok)
        expect(last_response.body).to be_json_eql("succeeded".to_json).at_path("status")
        expect(last_response.body).not_to have_json_path("_links/cancel")
      end
    end

    context "with another user's run" do
      let(:current_user) { create(:user) }

      before { get api_v3_paths.ai_text_transform_run(run.uuid) }

      it_behaves_like "not found"
    end

    context "with another user's run as admin" do
      let(:current_user) { create(:admin) }

      before { get api_v3_paths.ai_text_transform_run(run.uuid) }

      it_behaves_like "not found"
    end

    context "with an unknown uuid" do
      before { get api_v3_paths.ai_text_transform_run(SecureRandom.uuid) }

      it_behaves_like "not found"
    end
  end

  describe "POST /api/v3/ai_text_transform_runs/:uuid/cancel" do
    let(:run) { create(:ai_text_transform_run, user:, action:) }

    context "with a queued run" do
      before { post_cancel(run) }

      it_behaves_like "successful no content response"

      it "requests cancellation" do
        expect(run.reload.cancel_requested).to be(true)
      end
    end

    context "when cancelled twice" do
      before { 2.times { post_cancel(run) } }

      it_behaves_like "successful no content response"

      it "keeps the flag set" do
        expect(run.reload.cancel_requested).to be(true)
      end
    end

    context "with a terminal run" do
      before do
        run.finish!("succeeded")
        post_cancel(run)
      end

      it_behaves_like "successful no content response"

      it "leaves the run untouched" do
        expect(run.reload).to have_attributes(cancel_requested: false, status: "succeeded")
      end
    end

    context "with another user's run" do
      let(:current_user) { create(:user) }

      before { post_cancel(run) }

      it_behaves_like "not found"

      it "leaves the run untouched" do
        expect(run.reload.cancel_requested).to be(false)
      end
    end
  end
end
