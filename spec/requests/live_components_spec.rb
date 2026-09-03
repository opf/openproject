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

  let(:component_state) { :edit }
  let(:props) do
    Documents::ShowEditView::PageHeaderComponent.serialize_props(document:, state: component_state)
  end
  let(:reflexes) { [] }

  let(:state) do
    {
      ruby_class: "Documents::ShowEditView::PageHeaderComponent",
      props:,
      slots: {},
      children: {}
    }
  end

  let(:payload) { { state:, reflexes: }.to_json }
  let(:body) { { payload: LiveComponent::Payload.encode(payload, compress: false) }.to_json }

  # This is a plain `type: :request` spec (auto-inferred from the file's
  # location under spec/requests), which wires up `post`/`get` via
  # Rack::Test::Methods (see spec/support/rspec_request_specs.rb) rather
  # than ActionDispatch::Integration -- hence the positional params/env
  # args here, matching the house style used by the JSON API request specs
  # (e.g. spec/requests/api/v3/work_packages/create_form_resource_spec.rb).
  def post_render(content_type: "application/json")
    post "/live_components/render", body, "CONTENT_TYPE" => content_type
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
    Base64.decode64(response.body) # the endpoint never compresses
  end

  def update_title_reflex(title)
    [{ method_name: "update_title", props: { title: } }]
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

    # `serializes :document, attributes: false`. The library's default
    # (`attributes: true`) writes every column of the record into the
    # `data-state` attribute of the served markup, and with `reload: true`
    # deserialization discards it anyway -- so it is pure disclosure.
    it "does not serialize the document's columns into data-state" do
      post_render

      # `created_at` is a column on both records and appears nowhere in the
      # rendered markup, so it only shows up here if the props were serialized
      # with the library's default `attributes: true`.
      expect(decoded_response_html).not_to include("created_at")
    end

    context "with an update_title reflex" do
      let(:reflexes) { update_title_reflex("Reflexed title") }

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
      let(:reflexes) { update_title_reflex("") }

      it "leaves the document unchanged and re-renders in the edit state with the error" do
        original_title = document.title

        post_render

        expect(response).to have_http_status(:ok)
        expect(document.reload.title).to eq(original_title)

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

    let(:component_state) { :show }
    let(:reflexes) { update_title_reflex("Attacker title") }

    before { login_as(view_only_user) }

    it "does not update the document or render an edit affordance" do
      original_title = document.title

      post_render

      expect(response).to have_http_status(:ok)
      expect(document.reload.title).to eq(original_title)

      html = decoded_response_html
      expect(html).to include(document.title)
      expect(html).not_to include("document_title")
    end

    # #display_state downgrades a client-requested :edit to :show when the
    # caller cannot manage documents. This is the only example that exercises
    # that branch: the reader *can* see the document, so RenderGuard lets the
    # render through and the downgrade is what suppresses the form.
    context "and requesting the edit state" do
      let(:component_state) { :edit }
      let(:reflexes) { [] }

      it "downgrades to the show state instead of rendering the edit form" do
        post_render

        expect(response).to have_http_status(:ok)
        html = decoded_response_html
        expect(html).to include(document.title)
        expect(html).not_to include("document_title")
      end
    end
  end

  context "when logged in without project permission" do
    # A user with no membership/permission at all on the project. The
    # controller performs no record-level authorization itself --
    # PageHeaderComponent's `RenderGuard` (prepended above
    # LiveComponent::Base::Overrides in the ancestor chain -- see the
    # component) short-circuits render_in entirely when render? is false, so a
    # request for a document the user cannot view yields a 200 with a
    # genuinely empty body: no visible markup, no edit affordance, and no
    # `data-state` attribute either. (An earlier version of this guard used a
    # bare `render?` without the prepended short-circuit; that suppressed only
    # the visible markup while `data-state` still leaked the document's full
    # serialized attributes. RenderGuard closes that gap by never letting
    # LiveComponent::Base's render_in wrapper run at all.)
    let(:unprivileged_user) { create(:user) }

    let(:component_state) { :show }

    before { login_as(unprivileged_user) }

    it "renders nothing at all -- not even data-state (component self-guards the read)" do
      post_render

      expect(response).to have_http_status(:ok)
      html = decoded_response_html
      expect(html).to eq("")
      expect(html).not_to include(document.title)
      expect(html).not_to include("document_title")
    end

    # A client-forged request for state: :edit. Same as above: RenderGuard
    # denies the read before PageHeaderComponent#display_state's
    # :edit-downgrade logic (or any serialization) even runs, so the
    # response is empty either way.
    context "and requesting edit state" do
      let(:component_state) { :edit }

      it "still renders nothing, without the edit form" do
        post_render

        expect(response).to have_http_status(:ok)
        html = decoded_response_html
        expect(html).to eq("")
        expect(html).not_to include(document.title)
        expect(html).not_to include("document_title")
      end
    end

    # RenderGuard cannot cover this: LiveComponent::RenderComponent dispatches
    # every reflex *before* it calls component.render_in. The empty body below
    # comes from the guard, but what stops the write is #update_title's own
    # `render?` check.
    context "and sending an update_title reflex" do
      let(:reflexes) { update_title_reflex("Attacker title") }

      it "does not dispatch the reflex" do
        original_title = document.title

        post_render

        expect(response).to have_http_status(:ok)
        expect(document.reload.title).to eq(original_title)
        expect(decoded_response_html).to eq("")
      end
    end
  end

  context "when not logged in" do
    it "does not render" do
      post_render

      # Observed: 302, not 401. ApplicationController#require_login redirects
      # HTML-format requests to the sign-in page rather than returning a 401
      # (that branch is reserved for xml/js/json/turbo_stream formats, and
      # this request doesn't set an Accept header). Either way, this must not
      # be a 200 with rendered component HTML.
      expect(response).to have_http_status(:found)
      expect(response.body).not_to include(document.title)
    end

    # `login_required` defaults to true, so the example above would pass even
    # without the controller's own `before_action :require_login`. Public
    # instances turn it off, which makes `check_if_login_required` a no-op --
    # this endpoint must still refuse anonymous callers.
    context "on a public instance", with_settings: { login_required: false } do
      it "still does not render" do
        post_render

        expect(response).to have_http_status(:found)
        expect(response.body).not_to include(document.title)
      end
    end
  end

  describe "payload validation" do
    before { login_as(user) }

    shared_examples "a rejected payload" do
      it "responds 400 without rendering" do
        post_render

        expect(response).to have_http_status(:bad_request)
        expect(response.body).not_to include(document.title)
      end
    end

    context "with a component class outside the allowlist" do
      let(:state) { super().merge(ruby_class: "Users::AvatarComponent") }

      it_behaves_like "a rejected payload"
    end

    # State.build recurses into children and slots, safe_constantize'ing each
    # nested ruby_class and running its deserialize_props -- reaching
    # ModelSerializer, and so arbitrary record loads, on a path with no
    # render? and no RenderGuard. Allowlisting the root alone does not bound
    # that, so the pilot requires both to be empty.
    context "with client-supplied children" do
      let(:state) do
        super().merge(children: { "x" => { "ruby_class" => "Users::AvatarComponent", "props" => {} } })
      end

      it_behaves_like "a rejected payload"
    end

    context "with client-supplied slots" do
      let(:state) { super().merge(slots: { "header" => [{ "props" => {} }] }) }

      it_behaves_like "a rejected payload"
    end

    # `project` used to be a prop of its own, deserialized independently of
    # `document` and authorized by nothing -- a mismatched pair leaked the
    # foreign project's name through the breadcrumbs and evaluated
    # manage_documents against a project of the client's choosing. It is now
    # derived from document.project, and naming it is rejected outright.
    context "with a project prop the component no longer accepts" do
      let(:other_project) { create(:project) }

      let(:props) do
        super().merge(project: { "_lc_ar" => { "gid" => other_project.to_global_id.to_s, "signed" => false } })
      end

      it_behaves_like "a rejected payload"
    end

    # Unknown prop names are not merely inert: LiveComponent::Base's
    # deserialize_props memoizes a serializer into a class-level hash keyed by
    # the client's own prop name, so each invented name is interned for the
    # life of the process.
    context "with an unknown prop name" do
      let(:props) { super().merge(nonsense_prop_name: 1) }

      it_behaves_like "a rejected payload"
    end

    # __lc_attributes is merged last into the rendered element's attributes,
    # so an unfiltered value can inject event handlers and override the
    # framework's own data-controller / data-component / data-id.
    context "with an event handler in __lc_attributes" do
      let(:props) { super().merge(__lc_attributes: { "onmouseover" => "alert(1)" }) }

      it_behaves_like "a rejected payload"
    end

    # What a real client actually posts: the server emits `__lc_attributes`
    # into data-state and the JS round-trips it verbatim, including the
    # serializer's own `_lc_symkeys` marker. Rejecting that marker breaks
    # every render (it did, until the browser spec caught it).
    context "with the __lc_attributes a real client round-trips" do
      let(:props) do
        super().merge(__lc_attributes: {
                        "id" => Documents::ShowEditView::PageHeaderComponent::DOM_ID,
                        "data-id" => "0865fbdf-b6e1-4675-ad6e-61773d2cb740",
                        LiveComponent::Serializer::SYMBOL_KEYS_KEY => []
                      })
      end

      it "renders" do
        post_render

        expect(response).to have_http_status(:ok)
        expect(decoded_response_html).to include("document_title")
      end
    end

    context "with _lc_symkeys naming an attribute outside the allowlist" do
      let(:props) do
        super().merge(__lc_attributes: { LiveComponent::Serializer::SYMBOL_KEYS_KEY => ["onmouseover"] })
      end

      it_behaves_like "a rejected payload"
    end

    context "with __lc_attributes overriding the framework's own attributes" do
      let(:props) { super().merge(__lc_attributes: { "data-controller" => "some-other-controller" }) }

      it_behaves_like "a rejected payload"
    end

    # SafeDispatcher permits any public method defined on any ViewComponent
    # subclass in the ancestor chain, so the reachable set is narrowed to an
    # explicit per-component allowlist in the controller.
    context "with a reflex outside the component's allowlist" do
      let(:reflexes) { [{ method_name: "display_state", props: {} }] }

      it_behaves_like "a rejected payload"
    end

    # Reflex argument values run through the full LiveComponent serializer,
    # which turns a client hash into an arbitrary record via an unsigned
    # GlobalID::Locator.locate.
    context "with a non-scalar reflex argument" do
      let(:reflexes) do
        [{ method_name: "update_title",
           props: { title: { "_lc_gid" => document.to_global_id.to_s } } }]
      end

      it_behaves_like "a rejected payload"
    end

    context "with more reflexes than the endpoint accepts" do
      let(:reflexes) { Array.new(LiveComponentsController::MAX_REFLEXES + 1) { update_title_reflex("x").first } }

      it_behaves_like "a rejected payload"
    end

    # Posted as text/plain on purpose: Rails' own params parser rejects a
    # malformed application/json body before the controller is reached, so
    # that route would exercise the middleware rather than #decode_payload.
    context "with a body that isn't JSON" do
      let(:body) { "not json at all" }

      it "responds 400 without rendering" do
        post_render(content_type: "text/plain")

        expect(response).to have_http_status(:bad_request)
        expect(response.body).not_to include(document.title)
      end
    end

    context "with a payload that isn't valid base64-encoded JSON" do
      let(:body) { { payload: "%%%" }.to_json }

      it_behaves_like "a rejected payload"
    end

    context "with valid JSON that isn't an object" do
      let(:body) { { payload: LiveComponent::Payload.encode("[1]", compress: false) }.to_json }

      it_behaves_like "a rejected payload"
    end

    # Payload.decode hands a gzip body straight to Zlib.gunzip with no size
    # cap, so the MAX_BODY_BYTES gate would sit on the wrong side of the
    # decompression. Our transport never compresses, so the compressed form
    # is refused outright.
    context "with a gzip-compressed payload" do
      let(:body) { { payload: LiveComponent::Payload.encode(payload, compress: true) }.to_json }

      it_behaves_like "a rejected payload"
    end

    context "with a body over the size cap" do
      let(:body) { { payload: "A" * (LiveComponentsController::MAX_BODY_BYTES + 1) }.to_json }

      it "responds 413 without decoding the body" do
        post_render

        expect(response).to have_http_status(:payload_too_large)
      end
    end
  end

  # The whole point of OpLiveComponentTransport sending X-CSRF-Token. Every
  # other example here runs with forgery protection disabled (:skip_csrf), so
  # this is the only one that exercises it.
  describe "forgery protection", skip_csrf: false do
    around do |example|
      previous = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = previous
    end

    before { login_as(user) }

    it "rejects a request without a CSRF token" do
      post_render

      expect(response).to have_http_status(422)
      expect(response.body).not_to include(document.title)
    end
  end
end
