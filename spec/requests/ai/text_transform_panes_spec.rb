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

RSpec.describe "AI text transform panes", :skip_csrf, type: :rails_request,
                                                      with_flag: { ai_text_transform_actions: true },
                                                      with_settings: { ai_text_transform_actions_enabled: true } do
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:work_package) { create(:work_package, project:, type:) }
  shared_let(:action) { create(:ai_text_transform_action, label: "Fix grammar") }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages add_work_packages] })
  end

  let(:request_id) { SecureRandom.uuid }
  let(:stream) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:pane_params) { { request_id:, scope: "selection", work_package_id: work_package.id } }
  let(:start_params) { pane_params.merge(action_id: action.id, input: "Login page dont work.") }

  current_user { user }

  before do
    allow(AI::TextTransforms::Gateway).to receive(:build).and_return(AI::TextTransforms::FakeGateway.new)
  end

  def run_with_events(status, *events)
    create(:ai_text_transform_run, status, user:, action:).tap do |run|
      events.each.with_index(1) { |(kind, payload), seq| create(:ai_text_transform_run_event, run:, seq:, kind:, payload:) }
    end
  end

  describe "POST create" do
    it "starts a run and appends the pane to the body" do
      expect { post ai_text_transform_panes_path, params: start_params, headers: stream }
        .to have_enqueued_job(AI::TextTransformJob)

      expect(AI::TextTransformRun.sole).to have_attributes(user:, input: "Login page dont work.", status: "queued")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('action="append"', 'targets="body"', 'id="ai-text-transforms-result-pane-component"',
                                       "Fix grammar", "Generating…", 'data-state="generating"',
                                       %(data-run="#{AI::TextTransformRun.sole.uuid}"), 'data-seq="0"')
    end

    it "starts a run for a new work package of a project and type" do
      post ai_text_transform_panes_path,
           params: start_params.except(:work_package_id).merge(project_id: project.id, type_id: type.id),
           headers: stream

      expect(response).to have_http_status(:ok)
      expect(AI::TextTransformRun.count).to eq(1)
    end

    it "repeats a run of the user's with its action and input" do
      failed = run_with_events(:failed, ["error", { "reason" => "upstream_error", "message" => "Failed." }])

      post ai_text_transform_panes_path, params: pane_params.merge(retry_of: failed.uuid), headers: stream

      retried = AI::TextTransformRun.where.not(id: failed.id).sole
      expect(retried).to have_attributes(action: failed.action, input: failed.input, status: "queued")
    end

    it "repeats a run for a new work package of a project and type" do
      failed = run_with_events(:failed, ["error", { "reason" => "upstream_error", "message" => "Failed." }])
      new_work_package = pane_params.except(:work_package_id).merge(project_id: project.id, type_id: type.id)

      post ai_text_transform_panes_path, params: new_work_package.merge(retry_of: failed.uuid), headers: stream

      expect(response).to have_http_status(:ok)
      expect(AI::TextTransformRun.where.not(id: failed.id).sole).to have_attributes(input: failed.input, status: "queued")
      expect(response.body).to include(%(name="project_id" value="#{project.id}"), %(name="type_id" value="#{type.id}"))
    end

    it "does not repeat a run that is still running" do
      running = run_with_events(:running)

      post ai_text_transform_panes_path, params: pane_params.merge(retry_of: running.uuid), headers: stream

      expect(response).to have_http_status(:not_found)
      expect(AI::TextTransformRun.count).to eq(1)
    end

    it "does not repeat another user's run" do
      other = create(:ai_text_transform_run, :failed)

      post ai_text_transform_panes_path, params: pane_params.merge(retry_of: other.uuid), headers: stream

      expect(response).to have_http_status(:not_found)
      expect(AI::TextTransformRun.count).to eq(1)
    end

    it "renders the pane as failed when the action is not available" do
      inactive = create(:ai_text_transform_action, label: "Inactive", active: false)

      post ai_text_transform_panes_path, params: start_params.merge(action_id: inactive.id), headers: stream

      expect(response).to have_http_status(:ok)
      expect(AI::TextTransformRun.count).to eq(0)
      expect(response.body).to include('action="append"', "Inactive", "Generation failed")
    end

    context "without the permission to edit the work package" do
      current_user { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

      it "is forbidden" do
        post ai_text_transform_panes_path, params: start_params, headers: stream

        expect(response).to have_http_status(:forbidden)
        expect(AI::TextTransformRun.count).to eq(0)
      end
    end

    it "does not find an invisible work package" do
      post ai_text_transform_panes_path, params: start_params.merge(work_package_id: create(:work_package).id), headers: stream

      expect(response).to have_http_status(:not_found)
    end

    it "does not find a type that is not enabled in the project" do
      other_type = create(:type)

      post ai_text_transform_panes_path,
           params: start_params.except(:work_package_id).merge(project_id: project.id, type_id: other_type.id),
           headers: stream

      expect(response).to have_http_status(:not_found)
      expect(AI::TextTransformRun.count).to eq(0)
    end

    it "rejects invalid parameters" do
      post ai_text_transform_panes_path, params: start_params.merge(request_id: "pane-1"), headers: stream

      expect(response).to have_http_status(:bad_request)
      expect(AI::TextTransformRun.count).to eq(0)
    end

    context "when not logged in" do
      current_user { User.anonymous }

      it "starts no run" do
        post ai_text_transform_panes_path, params: start_params, headers: stream

        expect(response).to have_http_status(:unauthorized)
        expect(AI::TextTransformRun.count).to eq(0)
      end
    end
  end

  context "with the feature flag inactive", with_flag: { ai_text_transform_actions: false } do
    let(:run) { run_with_events(:succeeded, ["completed", { "text" => "Done." }]) }

    it "is not found for create" do
      post ai_text_transform_panes_path, params: start_params, headers: stream

      expect(response).to have_http_status(:not_found)
    end

    {
      show: %i[get ai_text_transform_pane_path],
      destroy: %i[delete ai_text_transform_pane_path],
      apply: %i[post apply_ai_text_transform_pane_path],
      cancel: %i[post cancel_ai_text_transform_pane_path]
    }.each do |name, (verb, path_helper)|
      it "is not found for #{name}" do
        public_send(verb, public_send(path_helper, run.uuid), params: pane_params, headers: stream)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET show" do
    it "answers without content while nothing new happened" do
      run = run_with_events(:running, ["status", { "status" => "running" }])

      get ai_text_transform_pane_path(run.uuid, **pane_params, after: 1), headers: stream

      expect(response).to have_http_status(:no_content)
    end

    it "answers without content once the client has seen the final state" do
      run = run_with_events(:succeeded, ["completed", { "text" => "Done." }])

      get ai_text_transform_pane_path(run.uuid, **pane_params, after: 1, state: "done"), headers: stream

      expect(response).to have_http_status(:no_content)
    end

    it "updates a pane whose run finished after its last event" do
      run = run_with_events(:succeeded, ["completed", { "text" => "Done." }])

      get ai_text_transform_pane_path(run.uuid, **pane_params, after: 1, state: "generating"), headers: stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Replace")
    end

    it "updates a pane that carries no context" do
      run = run_with_events(:running, ["text_delta", { "delta" => "Text" }])

      get ai_text_transform_pane_path(run.uuid, **pane_params.except(:work_package_id)), headers: stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Text")
    end

    it "streams the text so far as formatted html" do
      run = run_with_events(:running, ["status", { "status" => "running" }], ["text_delta", { "delta" => "**bold** text" }])

      get ai_text_transform_pane_path(run.uuid, **pane_params, after: 1), headers: stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('action="update"', 'target="ai-text-transforms-result-pane-component-body"',
                                       'target="ai-text-transforms-result-pane-component-footer"',
                                       "<strong>bold</strong> text", "Generating…",
                                       'data-state="generating"', %(data-run="#{run.uuid}"), 'data-seq="2"')
    end

    it "offers the raw text once completed" do
      run = run_with_events(:succeeded, ["completed", { "text" => "**done**" }])

      get ai_text_transform_pane_path(run.uuid, **pane_params, after: 0), headers: stream

      expect(response.body).to include("<strong>done</strong>", "<template>**done**</template>", "Replace",
                                       'data-state="done"', apply_ai_text_transform_pane_path(run.uuid))
    end

    it "keeps markup in the raw text inside its template" do
      run = run_with_events(:succeeded, ["completed", { "text" => %(a < b "quoted" </template><img src=x>) }])

      get ai_text_transform_pane_path(run.uuid, **pane_params), headers: stream

      expect(response.body).to include("a &lt; b &quot;quoted&quot; &lt;/template&gt;&lt;img src=x&gt;")
      expect(response.body).not_to include("<img src=x>")
    end

    it "shows the stopped state for a blocked response" do
      run = run_with_events(:failed, ["error", { "reason" => "blocked", "message" => "Blocked." }])

      get ai_text_transform_pane_path(run.uuid, **pane_params), headers: stream

      expect(response.body).to include("Generation stopped", "Try again", 'data-state="stopped"',
                                       %(name="retry_of" value="#{run.uuid}"))
    end

    it "removes the pane of a cancelled run and reports the closed request" do
      run = run_with_events(:cancelled)

      get ai_text_transform_pane_path(run.uuid, **pane_params), headers: stream

      expect(response.body).to include('action="remove"', "op-dispatched:ai-text-transform:closed", request_id)
    end

    it "is forbidden once the permission to edit the work package is gone" do
      run = run_with_events(:succeeded, ["completed", { "text" => "Done." }])
      viewable = create(:project, types: [type])
      create(:member, project: viewable, principal: user, roles: [create(:project_role, permissions: %i[view_work_packages])])
      other = create(:work_package, project: viewable, type:)

      get ai_text_transform_pane_path(run.uuid, **pane_params, work_package_id: other.id), headers: stream

      expect(response).to have_http_status(:forbidden)
    end

    it "does not show another user's run" do
      run = create(:ai_text_transform_run, :running)

      get ai_text_transform_pane_path(run.uuid, **pane_params), headers: stream

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE destroy" do
    it "cancels a running run, removes the pane and reports the closed request" do
      run = run_with_events(:running)

      delete ai_text_transform_pane_path(run.uuid), params: pane_params, headers: stream

      expect(run.reload.cancel_requested).to be(true)
      expect(response.body).to include('action="remove"', 'target="ai-text-transforms-result-pane-component"',
                                       "op-dispatched:ai-text-transform:closed", request_id)
    end

    it "leaves a finished run as it is" do
      run = run_with_events(:succeeded, ["completed", { "text" => "Done." }])

      delete ai_text_transform_pane_path(run.uuid), params: pane_params, headers: stream

      expect(response).to have_http_status(:ok)
      expect(run.reload.cancel_requested).to be(false)
    end

    it "cancels the run even without a valid request id" do
      run = run_with_events(:running)

      delete ai_text_transform_pane_path(run.uuid), params: { request_id: "pane-1" }, headers: stream

      expect(response).to have_http_status(:ok)
      expect(run.reload.cancel_requested).to be(true)
      expect(response.body).to include('action="remove"')
      expect(response.body).not_to include("op-dispatched:ai-text-transform:closed")
    end

    it "closes a pane without a run" do
      delete ai_text_transform_pane_path("rejected"), params: pane_params, headers: stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('action="remove"', "op-dispatched:ai-text-transform:closed")
    end

    it "does not cancel another user's run" do
      run = create(:ai_text_transform_run, :running)

      delete ai_text_transform_pane_path(run.uuid), params: pane_params, headers: stream

      expect(run.reload.cancel_requested).to be(false)
    end
  end

  describe "POST apply" do
    it "hands the completed text of the run to the editor, never the client's" do
      text = %(Fixed < text "quoted" </template>)
      run = run_with_events(:succeeded, ["completed", { "text" => text }])

      post apply_ai_text_transform_pane_path(run.uuid), params: pane_params.merge(text: "Forged."), headers: stream

      expect(response.body).to include('action="dispatchEvent"', "op-dispatched:ai-text-transform:accepted")
      detail = JSON.parse(Nokogiri::HTML5.fragment(response.body).at("turbo-stream")["detail"])
      expect(detail).to eq("requestId" => request_id, "scope" => "selection", "text" => text)
    end

    context "without the permission to edit the work package any more" do
      current_user { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

      it "is forbidden" do
        run = create(:ai_text_transform_run, :succeeded, user: current_user, action:)

        post apply_ai_text_transform_pane_path(run.uuid), params: pane_params, headers: stream

        expect(response).to have_http_status(:forbidden)
        expect(response.body).not_to include("op-dispatched")
      end
    end

    it "refuses a run that has not succeeded" do
      run = run_with_events(:running)

      post apply_ai_text_transform_pane_path(run.uuid), params: pane_params, headers: stream

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not apply another user's run" do
      run = create(:ai_text_transform_run, :succeeded)

      post apply_ai_text_transform_pane_path(run.uuid), params: pane_params, headers: stream

      expect(response).to have_http_status(:not_found)
    end
  end

  context "with forgery protection", skip_csrf: false do
    it "renders forms that carry an authenticity token" do
      run = run_with_events(:succeeded, ["completed", { "text" => "Done." }])

      get ai_text_transform_pane_path(run.uuid, **pane_params), headers: stream

      expect(response.body.scan('name="authenticity_token"').size).to eq(2)
    end

    it "refuses to close a pane without a valid token" do
      run = run_with_events(:running)

      delete ai_text_transform_pane_path(run.uuid), params: pane_params, headers: stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(run.reload.cancel_requested).to be(false)
    end
  end

  describe "POST cancel" do
    it "requests cancellation of a running run" do
      run = run_with_events(:running)

      post cancel_ai_text_transform_pane_path(run.uuid)

      expect(response).to have_http_status(:no_content)
      expect(run.reload.cancel_requested).to be(true)
    end

    it "does not touch another user's run" do
      run = create(:ai_text_transform_run, :running)

      post cancel_ai_text_transform_pane_path(run.uuid)

      expect(response).to have_http_status(:not_found)
      expect(run.reload.cancel_requested).to be(false)
    end
  end
end
