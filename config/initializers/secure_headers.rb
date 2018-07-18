SecureHeaders::Configuration.default do |config|
  config.cookies = {
    secure: true,
    httponly: true
  }
  # Add "; preload" and submit the site to hstspreload.org for best protection.
  config.hsts = "max-age=#{20.years.to_i}; includeSubdomains"
  config.x_frame_options = "SAMEORIGIN"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = "origin-when-cross-origin"

  # Valid for assets
  assets_src = ["'self'"]
  asset_host = OpenProject::Configuration.rails_asset_host
  assets_src << asset_host if asset_host.present?

  # Valid for iframes
  frame_src = %w['self' https://player.vimeo.com]

  # Default src
  default_src = %w('self')

  # Allow requests to CLI in dev mode
  connect_src = default_src

  if FrontendAssetHelper.assets_proxied?
    connect_src += %w[ws://localhost:* http://localhost:*]
    assets_src += %w[ws://localhost:* http://localhost:*]
  end

  config.csp = {
    preserve_schemes: true,

    # Fallback when no value is defined
    default_src: default_src,
    # Allowed uri in <base> tag
    base_uri: %w('self'),

    # Allow fonts from self, asset host, or DATA uri
    font_src: assets_src + %w(data:),
    # Form targets can only be self
    form_action: %w('self'),
    # Allow iframe from vimeo (welcome video)
    frame_src: frame_src + %w('self'),
    frame_ancestors: %w('self'),
    # Allow images from anywhere including data urls and blobs (used in resizing)
    img_src: %w(* data: blob:),
    # Allow scripts from self
    script_src: assets_src,
    # Allow unsafe-inline styles
    style_src: assets_src + %w('unsafe-inline'),
    # disallow all object-src
    object_src: %w('none'),

    # Connect sources for CLI in dev mode
    connect_src: connect_src
  }
end
