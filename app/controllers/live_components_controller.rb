# frozen_string_literal: true

# Re-render endpoint for the LiveComponent pilot (DREAM-784).
# Deliberately NOT the library's Rack middleware: inheriting from
# ApplicationController runs user_setup so User.current is populated and
# component-level permission checks behave like any other request.
class LiveComponentsController < ApplicationController
  # `no_authorization_required!` is only OpenProject's "did you remember to
  # authorize" tripwire -- it enforces nothing. Login is normally enforced by
  # `check_if_login_required`, which is a no-op when `Setting.login_required?`
  # is false (a supported configuration for public instances), so require it
  # explicitly: this endpoint renders client-named state and has no anonymous
  # use case.
  no_authorization_required! :render_component
  before_action :require_login

  # Every component reachable through this endpoint, mapped to the reflexes it
  # may have dispatched on it.
  #
  # This controller performs no record-level authorization of its own: the
  # client names the record to render, and the render endpoint reaches records
  # a given user may not be allowed to view. Component-level read guards are
  # therefore MANDATORY, not optional hardening. See the reporting notes in
  # DREAM-784 for the disclosure details behind this requirement.
  #
  # IMPORTANT: a bare `render?` override is NOT sufficient. Every
  # LiveComponent-adopting component added here must `prepend` its own guard
  # module (added *after* `include LiveComponent::Base`, so it sits above the
  # gem's render wrapper in the ancestor chain) that short-circuits `render_in`
  # to `"".html_safe` when `render?` is false -- see
  # PageHeaderComponent::RenderGuard for the pattern. And because
  # LiveComponent::RenderComponent dispatches reflexes *before* it calls
  # `component.render_in`, that guard does not cover reflexes either: each
  # reflex must authorize itself as well.
  ALLOWED_COMPONENTS = {
    "Documents::ShowEditView::PageHeaderComponent" => %w[update_title].freeze
  }.freeze

  MAX_BODY_BYTES = 1.megabyte

  # No pilot interaction sends more than one reflex per render.
  MAX_REFLEXES = 4

  # `__lc_attributes` is merged *last* into the rendered element's attributes
  # by LiveComponent::Base::Overrides#render_in, so an unfiltered client value
  # can add event-handler attributes and override the framework's own
  # data-controller / data-component / data-livecomponent / data-id -- the
  # attributes the client-side morph and targeting logic keys on. Accept only
  # the two keys the pilot legitimately round-trips.
  ALLOWED_LC_ATTRIBUTE_KEYS = %w[id data-id].freeze

  # The serializer records which of a hash's keys were Symbols in a sibling
  # `_lc_symkeys` entry (LiveComponent::Serializer::SYMBOL_KEYS_KEY), so it
  # rides along inside __lc_attributes and has to be permitted -- constrained
  # to naming only the attributes above.
  LC_SYMBOL_KEYS = LiveComponent::Serializer::SYMBOL_KEYS_KEY

  # Reflex argument values are run through the full LiveComponent serializer,
  # which turns client hashes into arbitrary records (`_lc_gid` -> an unsigned
  # GlobalID::Locator.locate) or arbitrary constants (`_lc_ser: "Module"` ->
  # String#constantize). The pilot's reflexes take scalars, so require scalars.
  SCALAR_PROP_TYPES = [String, Numeric, TrueClass, FalseClass, NilClass].freeze

  GZIP_MAGIC = "\x1F\x8B".b.freeze

  def render_component
    # Rack 2.2's SYMBOL_TO_STATUS_CODE has no :content_too_large -- the
    # symbol for 413 is :payload_too_large (verified against the app's
    # pinned Rack version; the "obvious" symbol name raises ArgumentError).
    return head :payload_too_large if request.content_length.to_i > MAX_BODY_BYTES

    payload = decode_payload
    return head :bad_request unless allowed_payload?(payload)

    # The request payload is JSON, but the response is raw HTML: the JS
    # client's Payload.decode only base64-decodes (and optionally gunzips) --
    # it never JSON.parses. This matches the library's own reference Rack
    # middleware (LiveComponent::Middleware#call), which encodes the render
    # result directly with no JSON wrapping.
    render plain: LiveComponent::Payload.encode(rendered_html(payload), compress: false),
           content_type: "text/html"
  end

  private

  def rendered_html(payload)
    render_to_string(
      LiveComponent::RenderComponent.new(payload["state"], payload["reflexes"] || []),
      layout: false
    )
  end

  def allowed_payload?(payload)
    return false unless payload.is_a?(Hash)

    state = payload["state"]

    allowed_state?(state) && allowed_reflexes?(payload["reflexes"] || [], state["ruby_class"])
  end

  # Returns the decoded payload, or nil when the request body wasn't
  # well-formed enough to decode: garbage JSON, a payload field that isn't
  # valid base64/JSON, or a payload of the wrong shape entirely.
  #
  # This deliberately does not call LiveComponent::Payload.decode. That method
  # hands a gzip body straight to Zlib.gunzip with no size cap, which puts the
  # MAX_BODY_BYTES gate above on the wrong side of the decompression: 1 MB of
  # gzip inflates to roughly 800 MB at DEFLATE's maximum ratio. Our transport
  # (OpLiveComponentTransport) never compresses, so reject the compressed form
  # outright rather than trying to bound the inflate.
  def decode_payload
    data = JSON.parse(request.body.read)
    return nil unless data.is_a?(Hash) && data["payload"].is_a?(String)

    raw = Base64.decode64(data["payload"])
    return nil if raw.start_with?(GZIP_MAGIC)

    JSON.parse(raw, max_nesting: 32)
  rescue JSON::ParserError, TypeError, NoMethodError, ArgumentError => e
    Rails.logger.debug { "LiveComponentsController: rejecting malformed payload (#{e.class}: #{e.message})" }
    nil
  end

  # The allowlist has to bound the *whole* state tree, not just the root.
  # LiveComponent::State.build recurses into `children` and `slots`, and each
  # nested `ruby_class` is safe_constantize'd and has its own
  # `deserialize_props` run -- which reaches ModelSerializer, and therefore
  # arbitrary record loads, on a path with no `render?` and no RenderGuard.
  # The pilot component declares no slots and renders no live children, so
  # require both to be empty rather than trying to validate them.
  def allowed_state?(state)
    return false unless state.is_a?(Hash)
    return false unless ALLOWED_COMPONENTS.key?(state["ruby_class"])
    return false unless empty_tree?(state["children"]) && empty_tree?(state["slots"])

    allowed_props?(state["props"], state["ruby_class"])
  end

  def empty_tree?(value)
    value.nil? || value == {}
  end

  # Unknown prop names are not merely useless. LiveComponent::Base's
  # `deserialize_props` memoizes a serializer into a *class-level* hash keyed
  # by the client's own prop name (`prop_serializers[k] ||= ...`), so every
  # invented name is interned for the life of the process.
  def allowed_props?(props, ruby_class)
    return false unless props.is_a?(Hash)
    return false unless props.keys.all? { |key| component_prop_names(ruby_class).include?(key.to_s) }

    allowed_lc_attributes?(props["__lc_attributes"])
  end

  def component_prop_names(ruby_class)
    @component_prop_names ||= {}
    @component_prop_names[ruby_class] ||= begin
      # Safe to constantize: allowed_state? has already checked the allowlist.
      init_args = ruby_class.constantize.__lc_init_args
      init_args.filter_map { |type, name| name.to_s if %i[key keyreq].include?(type) } + ["__lc_attributes"]
    end
  end

  def allowed_lc_attributes?(attributes)
    return true if attributes.nil?
    return false unless attributes.is_a?(Hash)

    attributes.all? { |key, value| allowed_lc_attribute?(key.to_s, value) }
  end

  def allowed_lc_attribute?(key, value)
    return allowed_lc_symbol_keys?(value) if key == LC_SYMBOL_KEYS

    ALLOWED_LC_ATTRIBUTE_KEYS.include?(key) && value.is_a?(String)
  end

  def allowed_lc_symbol_keys?(value)
    value.is_a?(Array) && value.all? { |name| ALLOWED_LC_ATTRIBUTE_KEYS.include?(name.to_s) }
  end

  # LiveComponent::SafeDispatcher accepts any public method defined on any
  # ViewComponent subclass in the receiver's ancestor chain -- `public` is an
  # API-design signal, not an authorization statement -- so narrow the
  # reachable set to an explicit per-component allowlist here.
  def allowed_reflexes?(reflexes, ruby_class)
    return false unless reflexes.is_a?(Array) && reflexes.size <= MAX_REFLEXES

    allowed = ALLOWED_COMPONENTS.fetch(ruby_class)

    reflexes.all? do |reflex|
      reflex.is_a?(Hash) &&
        allowed.include?(reflex["method_name"]) &&
        allowed_reflex_props?(reflex["props"])
    end
  end

  def allowed_reflex_props?(props)
    return true if props.nil?

    props.is_a?(Hash) && props.each_value.all? do |value|
      SCALAR_PROP_TYPES.any? { |type| value.is_a?(type) }
    end
  end
end
