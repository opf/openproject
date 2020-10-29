# frozen_string_literal: true
require "secure_headers/hash_helper"
require "secure_headers/headers/cookie"
require "secure_headers/headers/content_security_policy"
require "secure_headers/headers/x_frame_options"
require "secure_headers/headers/strict_transport_security"
require "secure_headers/headers/x_xss_protection"
require "secure_headers/headers/x_content_type_options"
require "secure_headers/headers/x_download_options"
require "secure_headers/headers/x_permitted_cross_domain_policies"
require "secure_headers/headers/referrer_policy"
require "secure_headers/headers/clear_site_data"
require "secure_headers/headers/expect_certificate_transparency"
require "secure_headers/middleware"
require "secure_headers/railtie"
require "secure_headers/view_helper"
require "singleton"
require "secure_headers/configuration"

# Provide SecureHeaders::OPT_OUT as a config value to disable a given header
module SecureHeaders
  class NoOpHeaderConfig
    include Singleton

    def boom(*args)
      raise "Illegal State: attempted to modify NoOpHeaderConfig. Create a new config instead."
    end

    def to_h
      {}
    end

    def dup
      self.class.instance
    end

    def opt_out?
      true
    end

    alias_method :[], :boom
    alias_method :[]=, :boom
    alias_method :keys, :boom
  end

  OPT_OUT = NoOpHeaderConfig.instance
  SECURE_HEADERS_CONFIG = "secure_headers_request_config".freeze
  NONCE_KEY = "secure_headers_content_security_policy_nonce".freeze
  HTTPS = "https".freeze
  CSP = ContentSecurityPolicy

  class << self
    # Public: override a given set of directives for the current request. If a
    # value already exists for a given directive, it will be overridden.
    #
    # If CSP was previously OPT_OUT, a new blank policy is used.
    #
    # additions - a hash containing directives. e.g.
    #    script_src: %w(another-host.com)
    def override_content_security_policy_directives(request, additions, target = nil)
      config, target = config_and_target(request, target)

      if [:both, :enforced].include?(target)
        if config.csp.opt_out?
          config.csp = ContentSecurityPolicyConfig.new({})
        end

        config.csp.merge!(additions)
      end

      if [:both, :report_only].include?(target)
        if config.csp_report_only.opt_out?
          config.csp_report_only = ContentSecurityPolicyReportOnlyConfig.new({})
        end

        config.csp_report_only.merge!(additions)
      end

      override_secure_headers_request_config(request, config)
    end

    # Public: appends source values to the current configuration. If no value
    # is set for a given directive, the value will be merged with the default-src
    # value. If a value exists for the given directive, the values will be combined.
    #
    # additions - a hash containing directives. e.g.
    #    script_src: %w(another-host.com)
    def append_content_security_policy_directives(request, additions, target = nil)
      config, target = config_and_target(request, target)

      if [:both, :enforced].include?(target) && !config.csp.opt_out?
        config.csp.append(additions)
      end

      if [:both, :report_only].include?(target) && !config.csp_report_only.opt_out?
        config.csp_report_only.append(additions)
      end

      override_secure_headers_request_config(request, config)
    end

    def use_content_security_policy_named_append(request, name)
      additions = SecureHeaders::Configuration.named_appends(name).call(request)
      append_content_security_policy_directives(request, additions)
    end

    # Public: override X-Frame-Options settings for this request.
    #
    # value - deny, sameorigin, or allowall
    #
    # Returns the current config
    def override_x_frame_options(request, value)
      config = config_for(request)
      config.update_x_frame_options(value)
      override_secure_headers_request_config(request, config)
    end

    # Public: opts out of setting a given header by creating a temporary config
    # and setting the given headers config to OPT_OUT.
    def opt_out_of_header(request, header_key)
      config = config_for(request)
      config.opt_out(header_key)
      override_secure_headers_request_config(request, config)
    end

    # Public: opts out of setting all headers by telling secure_headers to use
    # the NOOP configuration.
    def opt_out_of_all_protection(request)
      use_secure_headers_override(request, Configuration::NOOP_OVERRIDE)
    end

    # Public: Builds the hash of headers that should be applied base on the
    # request.
    #
    # StrictTransportSecurity is not applied to http requests.
    # See #config_for to determine which config is used for a given request.
    #
    # Returns a hash of header names => header values. The value
    # returned is meant to be merged into the header value from `@app.call(env)`
    # in Rack middleware.
    def header_hash_for(request)
      prevent_dup = true
      config = config_for(request, prevent_dup)
      config.validate_config!
      headers = config.generate_headers

      if request.scheme != HTTPS
        headers.delete(StrictTransportSecurity::HEADER_NAME)
      end
      headers
    end

    # Public: specify which named override will be used for this request.
    # Raises an argument error if no named override exists.
    #
    # name - the name of the previously configured override.
    def use_secure_headers_override(request, name)
      config = config_for(request)
      config.override(name)
      override_secure_headers_request_config(request, config)
    end

    # Public: gets or creates a nonce for CSP.
    #
    # The nonce will be added to script_src
    #
    # Returns the nonce
    def content_security_policy_script_nonce(request)
      content_security_policy_nonce(request, ContentSecurityPolicy::SCRIPT_SRC)
    end

    # Public: gets or creates a nonce for CSP.
    #
    # The nonce will be added to style_src
    #
    # Returns the nonce
    def content_security_policy_style_nonce(request)
      content_security_policy_nonce(request, ContentSecurityPolicy::STYLE_SRC)
    end

    # Public: Retreives the config for a given header type:
    #
    # Checks to see if there is an override for this request, then
    # Checks to see if a named override is used for this request, then
    # Falls back to the global config
    def config_for(request, prevent_dup = false)
      config = request.env[SECURE_HEADERS_CONFIG] ||
        Configuration.send(:default_config)


      # Global configs are frozen, per-request configs are not. When we're not
      # making modifications to the config, prevent_dup ensures we don't dup
      # the object unnecessarily. It's not necessarily frozen to begin with.
      if config.frozen? && !prevent_dup
        config.dup
      else
        config
      end
    end

    private
    TARGETS = [:both, :enforced, :report_only]
    def raise_on_unknown_target(target)
      unless TARGETS.include?(target)
        raise "Unrecognized target: #{target}. Must be [:both, :enforced, :report_only]"
      end
    end

    def config_and_target(request, target)
      config = config_for(request)
      target = guess_target(config) unless target
      raise_on_unknown_target(target)
      [config, target]
    end

    def guess_target(config)
      if !config.csp.opt_out? && !config.csp_report_only.opt_out?
        :both
      elsif !config.csp.opt_out?
        :enforced
      elsif !config.csp_report_only.opt_out?
        :report_only
      else
        :both
      end
    end

    # Private: gets or creates a nonce for CSP.
    #
    # Returns the nonce
    def content_security_policy_nonce(request, script_or_style)
      request.env[NONCE_KEY] ||= SecureRandom.base64(32).chomp
      nonce_key = script_or_style == ContentSecurityPolicy::SCRIPT_SRC ? :script_nonce : :style_nonce
      append_content_security_policy_directives(request, nonce_key => request.env[NONCE_KEY])
      request.env[NONCE_KEY]
    end

    # Private: convenience method for specifying which configuration object should
    # be used for this request.
    #
    # Returns the config.
    def override_secure_headers_request_config(request, config)
      request.env[SECURE_HEADERS_CONFIG] = config
    end
  end

  # These methods are mixed into controllers and delegate to the class method
  # with the same name.
  def use_secure_headers_override(name)
    SecureHeaders.use_secure_headers_override(request, name)
  end

  def content_security_policy_script_nonce
    SecureHeaders.content_security_policy_script_nonce(request)
  end

  def content_security_policy_style_nonce
    SecureHeaders.content_security_policy_style_nonce(request)
  end

  def opt_out_of_header(header_key)
    SecureHeaders.opt_out_of_header(request, header_key)
  end

  def append_content_security_policy_directives(additions)
    SecureHeaders.append_content_security_policy_directives(request, additions)
  end

  def override_content_security_policy_directives(additions)
    SecureHeaders.override_content_security_policy_directives(request, additions)
  end

  def override_x_frame_options(value)
    SecureHeaders.override_x_frame_options(request, value)
  end

  def use_content_security_policy_named_append(name)
    SecureHeaders.use_content_security_policy_named_append(request, name)
  end
end
