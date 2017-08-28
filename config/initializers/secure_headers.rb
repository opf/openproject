SecureHeaders::Configuration.default do |config|
  config.cookies = {
    secure: true,
    httponly: true
  }
  # Add "; preload" and submit the site to hstspreload.org for best protection.
  config.hsts = "max-age=#{20.years.to_i}; includeSubdomains"
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = "origin-when-cross-origin"

  # Valid for assets
  assets_src = ["'self'"]
  asset_host = OpenProject::Configuration.rails_asset_host
  assets_src << asset_host if asset_host.present?

  config.csp = {
    preserve_schemes: true,

    # Fallback when no value is defined
    default_src: %w(https: 'self'),
    # Allowed uri in <base> tag
    base_uri: %w('self'),

    # Allow fonts from self, asset host, or DATA uri
    font_src: assets_src + %w(data:),
    # Form targets can only be self
    form_action: %w('self'),
    # Allow iframe from vimeo (welcome video)
    frame_src: %w(https://*.vimeo.com),
    frame_ancestors: %w('self'),
    # Allow images from anywhere
    img_src: %w(*),
    # Allow scripts from self (not inline, but)
    script_src: %w('self'),
    # Allow unsafe-inline styles
    style_src: assets_src + %w('unsafe-inline'),
  }
end
