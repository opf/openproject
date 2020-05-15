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
  frame_src << OpenProject::Configuration[:security_badge_url]

  # Default src
  default_src = %w('self')

  # Allow requests to CLI in dev mode
  connect_src = default_src

  if OpenProject::Configuration.sentry_dsn.present?
    connect_src += [OpenProject::Configuration.sentry_host]
  end

  # Add proxy configuration for Angular CLI to csp
  if FrontendAssetHelper.assets_proxied?
    proxied = ['ws://localhost:*', 'http://localhost:*', FrontendAssetHelper.cli_proxy]
    connect_src += proxied
    assets_src += proxied
  end

  # Allow to extend the script-src in specific situations
  script_src = assets_src

  # Allow unsafe-eval for rack-mini-profiler
  if Rails.env.development? && ENV['OPENPROJECT_RACK_PROFILER_ENABLED']
    script_src += %w('unsafe-eval')
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
    script_src: script_src,
    # Allow unsafe-inline styles
    style_src: assets_src + %w('unsafe-inline'),
    # Allow object-src from Release API
    object_src: [OpenProject::Configuration[:security_badge_url]],

    # Connect sources for CLI in dev mode
    connect_src: connect_src
  }
end

SecureHeaders::Configuration.named_append(:oauth) do |request|
  hosts = request.controller_instance.try(:allowed_forms) || []

  { form_action: hosts }
end
