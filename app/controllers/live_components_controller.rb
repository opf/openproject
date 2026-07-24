# frozen_string_literal: true

# Re-render endpoint for the LiveComponent pilot (DREAM-784).
# Deliberately NOT the library's Rack middleware: inheriting from
# ApplicationController runs user_setup so User.current is populated and
# component-level permission checks behave like any other request.
class LiveComponentsController < ApplicationController
  # Renders a single component from client-provided state; the component
  # itself performs its permission checks against User.current.
  no_authorization_required! :render_component

  # Cheap hardening beyond the approved experiment scope: only the pilot
  # component may be named as the root. (Child/slot classes are not yet
  # checked -- production adoption needs a full allowlist.)
  ALLOWED_COMPONENTS = %w[Documents::ShowEditView::PageHeaderComponent].freeze

  def render_component
    data = JSON.parse(request.body.read)
    payload, compressed = LiveComponent::Payload.decode(data["payload"])

    unless ALLOWED_COMPONENTS.include?(payload.dig("state", "ruby_class"))
      return head :bad_request
    end

    html = render_to_string(
      LiveComponent::RenderComponent.new(payload["state"], payload["reflexes"] || []),
      layout: false
    )

    # The request payload is JSON (Payload.decode always JSON-parses it),
    # but the response is raw HTML: the JS client's Payload.decode only
    # base64-decodes (and optionally gunzips) -- it never JSON.parses.
    # This matches the library's own reference Rack middleware
    # (LiveComponent::Middleware#call), which encodes the render result
    # directly with no JSON wrapping.
    render plain: LiveComponent::Payload.encode(html, compress: compressed),
           content_type: "text/html"
  end
end
