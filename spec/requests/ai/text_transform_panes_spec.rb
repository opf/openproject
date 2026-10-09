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

RSpec.describe "AI text transform pane", :skip_csrf, type: :rails_request,
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
  let(:start_params) do
    { action_id: action.id, input: "Login page dont work.", scope: "selection", request_id:, work_package_id: work_package.id }
  end

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

      run = AI::TextTransformRun.sole
      expect(run).to have_attributes(user:, input: "Login page dont work.", status: "queued")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('action="append"', 'targets="body"', 'id="ai-text-transforms-result-pane-component"')
      expect(response.body).to include("Fix grammar", "Selected text", %(data-state="generating"), %(data-run="#{run.uuid}"))
    end

    it "repeats a run of the user's with its action and input" do
      failed = run_with_events(:failed, ["error", { "reason" => "upstream_error", "message" => "Failed." }])

      post ai_text_transform_panes_path,
           params: { retry_of: failed.uuid, scope: "document", request_id:, work_package_id: work_package.id },
           headers: stream

      retried = AI::TextTransformRun.where.not(id: failed.id).sole
      expect(retried).to have_attributes(action: failed.action, input: failed.input, status: "queued")
    end

    it "does not repeat another user's run" do
      other = create(:ai_text_transform_run, :failed)

      post ai_text_transform_panes_path, params: { retry_of: other.uuid, request_id: }, headers: stream

      expect(response).to have_http_status(:not_found)
    end

    it "renders the pane as failed when the action is not available" do
      action.update!(active: false)

      post ai_text_transform_panes_path, params: start_params, headers: stream

      expect(AI::TextTransformRun.count).to eq(0)
      expect(response.body).to include(%(data-state="failed"), "Generation failed")
    ensure
      action.update!(active: true)
    end

    it "is forbidden without the permission to edit the work package" do
      user.members.sole.roles.sole.remove_permission!(:edit_work_packages)

      post ai_text_transform_panes_path, params: start_params, headers: stream

      expect(response).to have_http_status(:forbidden)
      expect(AI::TextTransformRun.count).to eq(0)
    end
  end

  describe "GET show" do
    it "answers without content while nothing new happened" do
      run = run_with_events(:running, ["status", { "status" => "running" }])

      get ai_text_transform_pane_path(run.uuid, after: 1, request_id:), headers: stream

      expect(response).to have_http_status(:no_content)
    end

    it "streams the text so far as formatted html" do
      run = run_with_events(:running, ["status", { "status" => "running" }], ["text_delta", { "delta" => "**bold** text" }])

      get ai_text_transform_pane_path(run.uuid, after: 1, request_id:), headers: stream

      expect(response.body).to include("<strong>bold</strong> text", %(data-seq="2"), %(data-state="generating"))
    end

    it "offers the raw text and the apply form once completed" do
      run = run_with_events(:succeeded, ["completed", { "text" => "**done**" }])

      get ai_text_transform_pane_path(run.uuid, after: 0, request_id:), headers: stream

      expect(response.body).to include(%(data-state="done"), "<strong>done</strong>", "**done**",
                                       apply_ai_text_transform_pane_path(run.uuid))
    end

    it "shows the stopped state for a blocked response" do
      run = run_with_events(:failed, ["error", { "reason" => "blocked", "message" => "Blocked." }])

      get ai_text_transform_pane_path(run.uuid, request_id:), headers: stream

      expect(response.body).to include(%(data-state="stopped"), "Generation stopped", %(name="retry_of" value="#{run.uuid}"))
    end

    it "does not show another user's run" do
      run = create(:ai_text_transform_run, :running)

      get ai_text_transform_pane_path(run.uuid), headers: stream

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE destroy" do
    it "cancels a running run, removes the pane and reports the closed request" do
      run = run_with_events(:running)

      delete ai_text_transform_pane_path(run.uuid), params: { request_id: }, headers: stream

      expect(run.reload.cancel_requested).to be(true)
      expect(response.body).to include('action="remove"', "op-dispatched:ai-text-transform:closed", request_id)
    end

    it "closes a pane without a run" do
      delete ai_text_transform_pane_path("rejected"), params: { request_id: }, headers: stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('action="remove"')
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

  describe "POST apply" do
    it "hands the completed text to the editor" do
      run = run_with_events(:succeeded, ["completed", { "text" => "Fixed text." }])

      post apply_ai_text_transform_pane_path(run.uuid), params: { request_id:, scope: "selection" }, headers: stream

      expect(response.body).to include('action="dispatchEvent"', "op-dispatched:ai-text-transform:apply")
      detail = JSON.parse(Nokogiri::HTML5.fragment(response.body).at("turbo-stream")["detail"])
      expect(detail).to eq("requestId" => request_id, "scope" => "selection", "text" => "Fixed text.")
    end

    it "refuses a run that has not succeeded" do
      run = run_with_events(:running)

      post apply_ai_text_transform_pane_path(run.uuid), params: { request_id: }, headers: stream

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
