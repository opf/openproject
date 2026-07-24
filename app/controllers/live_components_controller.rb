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
  #
  # This controller performs no record-level authorization of its own: the
  # client names the record to render, and the render endpoint reaches records
  # a given user may not be allowed to view. Component-level read guards are
  # therefore MANDATORY, not optional hardening. See the reporting notes in
  # DREAM-784 for the disclosure details behind this requirement.
  #
  # IMPORTANT: a bare `render?` override is NOT sufficient. Every
  # LiveComponent-adopting component added to this allowlist must `prepend`
  # its own guard module (added *after* `include LiveComponent::Base`, so it
  # sits above the gem's render wrapper in the ancestor chain) that
  # short-circuits `render_in` to `"".html_safe` when `render?` is false --
  # see PageHeaderComponent::RenderGuard for the pattern.
  ALLOWED_COMPONENTS = %w[Documents::ShowEditView::PageHeaderComponent].freeze

  # Client-supplied gzip is decompressed unbounded by the library (Payload.decode
  # calls Zlib.gunzip with no size cap), so an attacker can trade a small request
  # body for a large in-memory inflate. Reject oversized bodies before that runs.
  MAX_BODY_BYTES = 1.megabyte

  def render_component
    # Rack 2.2's SYMBOL_TO_STATUS_CODE has no :content_too_large -- the
    # symbol for 413 is :payload_too_large (verified against the app's
    # pinned Rack version; the "obvious" symbol name raises ArgumentError).
    return head :payload_too_large if request.content_length.to_i > MAX_BODY_BYTES

    payload, compressed = decode_payload
    return head :bad_request unless allowed_payload?(payload)

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

  private

  # Returns [payload, compressed] on success. On failure returns bare nil
  # (which destructures to payload: nil, compressed: nil for the caller) --
  # the request body wasn't well-formed enough to decode: garbage JSON, a
  # payload field that isn't valid base64/gzip/JSON, or a payload of the
  # wrong shape entirely.
  # The exact exception list was verified empirically (bundle exec rails
  # runner fed garbage strings to JSON.parse/Payload.decode and recorded
  # what actually raised): JSON::ParserError, TypeError, NoMethodError, and
  # Zlib::Error (covers Zlib::GzipFile::Error/LengthError, both subclasses).
  # ArgumentError never came up despite being the brief's first guess, so
  # it's deliberately not rescued here.
  def decode_payload
    data = JSON.parse(request.body.read)
    LiveComponent::Payload.decode(data["payload"])
  rescue JSON::ParserError, Zlib::Error, TypeError, NoMethodError => e
    Rails.logger.debug { "LiveComponentsController: rejecting malformed payload (#{e.class}: #{e.message})" }
    nil
  end

  def allowed_payload?(payload)
    # Valid JSON that isn't an object ("[1]", "\"x\"") survives decoding;
    # reject it here rather than letting #dig raise on an Array or String.
    return false unless payload.is_a?(Hash)

    ALLOWED_COMPONENTS.include?(payload.dig("state", "ruby_class"))
  end
end
