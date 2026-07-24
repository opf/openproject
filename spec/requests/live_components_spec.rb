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

RSpec.describe "LiveComponents render endpoint", :skip_csrf do
  subject(:response) { last_response }

  shared_let(:project) { create(:project, enabled_module_names: %i[documents]) }
  shared_let(:document) { create(:document, project:) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_documents manage_documents] }) }

  let(:state) do
    {
      ruby_class: "Documents::ShowEditView::PageHeaderComponent",
      props: Documents::ShowEditView::PageHeaderComponent.serialize_props(
        document:, project:, state: :edit
      ),
      slots: {},
      children: {}
    }
  end

  let(:body) do
    { payload: LiveComponent::Payload.encode({ state:, reflexes: [] }.to_json, compress: false) }.to_json
  end

  # This is a plain `type: :request` spec (auto-inferred from the file's
  # location under spec/requests), which wires up `post`/`get` via
  # Rack::Test::Methods (see spec/support/rspec_request_specs.rb) rather
  # than ActionDispatch::Integration -- hence the positional params/env
  # args here, matching the house style used by the JSON API request specs
  # (e.g. spec/requests/api/v3/work_packages/create_form_resource_spec.rb).
  def post_render
    post "/live_components/render", body, "CONTENT_TYPE" => "application/json"
  end

  # Request/response payloads are asymmetric BY DESIGN: request payloads
  # are JSON (state/reflexes), so `LiveComponent::Payload.decode` is right
  # for those -- it always JSON.parses. But *response* HTML is decoded by
  # the JS client's own `decode` (base64 -> optional gunzip -> raw text,
  # no JSON.parse), matching the library's reference Rack middleware
  # (`LiveComponent::Middleware#call`, which encodes the render result
  # directly with no JSON wrapping). Don't use `Payload.decode` on the
  # response body -- decode it the way the real client does.
  def decoded_response_html
    Base64.decode64(response.body) # spec always posts compress: false
  end

  context "when logged in with permission" do
    before { login_as(user) }

    it "re-renders the component in the requested state" do
      post_render

      expect(response).to have_http_status(:ok)
      html = decoded_response_html
      expect(html).to include("data-component=\"Documents::ShowEditView::PageHeaderComponent\"")
      expect(html).to include("document_title") # edit-state input rendered
    end

    context "with an update_title reflex" do
      let(:body) do
        {
          payload: LiveComponent::Payload.encode(
            {
              state:,
              reflexes: [{ method_name: "update_title", props: { title: "Reflexed title" } }]
            }.to_json,
            compress: false
          )
        }.to_json
      end

      it "updates the document and re-renders in the show state" do
        post_render

        expect(response).to have_http_status(:ok)
        expect(document.reload.title).to eq("Reflexed title")

        html = decoded_response_html
        expect(html).to include("Reflexed title")
        expect(html).not_to include("document_title") # edit-state input gone
      end
    end

    context "with an update_title reflex sending a blank title" do
      let(:body) do
        {
          payload: LiveComponent::Payload.encode(
            {
              state:,
              reflexes: [{ method_name: "update_title", props: { title: "" } }]
            }.to_json,
            compress: false
          )
        }.to_json
      end

      it "leaves the document unchanged and re-renders in the edit state with the error" do
        post_render

        expect(response).to have_http_status(:ok)
        expect(document.reload.title).not_to eq("")

        html = decoded_response_html
        expect(html).to match(/can(?:&#39;|')t be blank/)
        expect(html).to include("document_title") # still in edit state
      end
    end
  end

  context "when logged in without manage_documents permission" do
    let(:view_only_user) do
      create(:user, member_with_permissions: { project => %i[view_documents] })
    end

    let(:state) { super().merge(props: Documents::ShowEditView::PageHeaderComponent.serialize_props(document:, project:, state: :show)) }

    let(:body) do
      {
        payload: LiveComponent::Payload.encode(
          {
            state:,
            reflexes: [{ method_name: "update_title", props: { title: "Attacker title" } }]
          }.to_json,
          compress: false
        )
      }.to_json
    end

    before { login_as(view_only_user) }

    it "does not update the document or render an edit affordance" do
      post_render

      expect(response).to have_http_status(:ok)
      expect(document.reload.title).not_to eq("Attacker title")

      html = decoded_response_html
      expect(html).to include(document.title)
      expect(html).not_to include("document_title")
    end
  end

  context "when logged in without project permission" do
    # A user with no membership/permission at all on the project. The
    # controller performs no authorization itself -- the component is
    # expected to gate its own edit affordances based on User.current.
    let(:unprivileged_user) { create(:user) }

    let(:state) { super().merge(props: Documents::ShowEditView::PageHeaderComponent.serialize_props(document:, project:, state: :show)) }

    before { login_as(unprivileged_user) }

    it "renders the component without edit affordances" do
      post_render

      expect(response).to have_http_status(:ok)
      html = decoded_response_html
      expect(html).to include(document.title)
      expect(html).not_to include("Edit title")
    end

    # A client-forged request for state: :edit. PageHeaderComponent#display_state
    # downgrades this to :show rather than raising (see the component), which
    # is also what keeps Primer::OpenProject::PageHeader::Title#render? happy --
    # it requires either show state or a populated editable_form slot, and this
    # component never populates that slot.
    context "and requesting edit state" do
      let(:state) { super().merge(props: Documents::ShowEditView::PageHeaderComponent.serialize_props(document:, project:, state: :edit)) }

      it "still renders as show, without the edit form" do
        post_render

        expect(response).to have_http_status(:ok)
        html = decoded_response_html
        expect(html).to include(document.title)
        expect(html).not_to include("document_title")
      end
    end
  end

  context "when not logged in" do
    it "does not render" do
      post_render

      # Observed: 302, not 401. OpenProject's default `login_required`
      # setting is true, and ApplicationController#require_login redirects
      # HTML-format requests to the sign-in page rather than returning a
      # 401 (that branch is reserved for xml/js/json/turbo_stream formats,
      # and this request doesn't set an Accept header). Either way, this
      # must not be a 200 with rendered component HTML.
      expect(response).to have_http_status(:found)
      expect(response.body).not_to include(document.title)
    end
  end

  context "with a component class outside the allowlist" do
    before { login_as(user) }

    let(:state) { super().merge(ruby_class: "Users::AvatarComponent") }

    it "rejects the request" do
      post_render

      expect(response).to have_http_status(:bad_request)
    end
  end
end
