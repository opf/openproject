# frozen_string_literal: true
module SecureHeaders
  module ViewHelpers
    include SecureHeaders::HashHelper
    SECURE_HEADERS_RAKE_TASK = "rake secure_headers:generate_hashes"

    class UnexpectedHashedScriptException < StandardError; end

    # Public: create a style tag using the content security policy nonce.
    # Instructs secure_headers to append a nonce to style-src directive.
    #
    # Returns an html-safe style tag with the nonce attribute.
    def nonced_style_tag(content_or_options = {}, &block)
      nonced_tag(:style, content_or_options, block)
    end

    # Public: create a stylesheet link tag using the content security policy nonce.
    # Instructs secure_headers to append a nonce to style-src directive.
    #
    # Returns an html-safe link tag with the nonce attribute.
    def nonced_stylesheet_link_tag(*args, &block)
      opts = extract_options(args).merge(nonce: _content_security_policy_nonce(:style))

      stylesheet_link_tag(*args, **opts, &block)
    end

    # Public: create a script tag using the content security policy nonce.
    # Instructs secure_headers to append a nonce to script-src directive.
    #
    # Returns an html-safe script tag with the nonce attribute.
    def nonced_javascript_tag(content_or_options = {}, &block)
      nonced_tag(:script, content_or_options, block)
    end

    # Public: create a script src tag using the content security policy nonce.
    # Instructs secure_headers to append a nonce to script-src directive.
    #
    # Returns an html-safe script tag with the nonce attribute.
    def nonced_javascript_include_tag(*args, &block)
      opts = extract_options(args).merge(nonce: _content_security_policy_nonce(:script))

      javascript_include_tag(*args, **opts, &block)
    end

    # Public: create a script Webpacker pack tag using the content security policy nonce.
    # Instructs secure_headers to append a nonce to script-src directive.
    #
    # Returns an html-safe script tag with the nonce attribute.
    def nonced_javascript_pack_tag(*args, &block)
      opts = extract_options(args).merge(nonce: _content_security_policy_nonce(:script))

      javascript_pack_tag(*args, **opts, &block)
    end

    # Public: create a stylesheet Webpacker link tag using the content security policy nonce.
    # Instructs secure_headers to append a nonce to style-src directive.
    #
    # Returns an html-safe link tag with the nonce attribute.
    def nonced_stylesheet_pack_tag(*args, &block)
      opts = extract_options(args).merge(nonce: _content_security_policy_nonce(:style))

      stylesheet_pack_tag(*args, **opts, &block)
    end

    # Public: use the content security policy nonce for this request directly.
    # Instructs secure_headers to append a nonce to style/script-src directives.
    #
    # Returns a non-html-safe nonce value.
    def _content_security_policy_nonce(type)
      case type
      when :script
        SecureHeaders.content_security_policy_script_nonce(@_request)
      when :style
        SecureHeaders.content_security_policy_style_nonce(@_request)
      end
    end
    alias_method :content_security_policy_nonce, :_content_security_policy_nonce

    def content_security_policy_script_nonce
      _content_security_policy_nonce(:script)
    end

    def content_security_policy_style_nonce
      _content_security_policy_nonce(:style)
    end

    ##
    # Checks to see if the hashed code is expected and adds the hash source
    # value to the current CSP.
    #
    # By default, in development/test/etc. an exception will be raised.
    def hashed_javascript_tag(raise_error_on_unrecognized_hash = nil, &block)
      hashed_tag(
        :script,
        :script_src,
        Configuration.instance_variable_get(:@script_hashes),
        raise_error_on_unrecognized_hash,
        block
      )
    end

    def hashed_style_tag(raise_error_on_unrecognized_hash = nil, &block)
      hashed_tag(
        :style,
        :style_src,
        Configuration.instance_variable_get(:@style_hashes),
        raise_error_on_unrecognized_hash,
        block
      )
    end

    private

    def hashed_tag(type, directive, hashes, raise_error_on_unrecognized_hash, block)
      if raise_error_on_unrecognized_hash.nil?
        raise_error_on_unrecognized_hash = ENV["RAILS_ENV"] != "production"
      end

      content = capture(&block)
      file_path = File.join("app", "views", self.instance_variable_get(:@virtual_path) + ".html.erb")

      if raise_error_on_unrecognized_hash
        hash_value = hash_source(content)
        message = unexpected_hash_error_message(file_path, content, hash_value)

        if hashes.nil? || hashes[file_path].nil? || !hashes[file_path].include?(hash_value)
          raise UnexpectedHashedScriptException.new(message)
        end
      end

      SecureHeaders.append_content_security_policy_directives(request, directive => hashes[file_path])

      content_tag type, content
    end

    def unexpected_hash_error_message(file_path, content, hash_value)
      <<-EOF
\n\n*** WARNING: Unrecognized hash in #{file_path}!!! Value: #{hash_value} ***
#{content}
*** Run #{SECURE_HEADERS_RAKE_TASK} or add the following to config/secure_headers_generated_hashes.yml:***
#{file_path}:
- \"#{hash_value}\"\n\n
      NOTE: dynamic javascript is not supported using script hash integration
      on purpose. It defeats the point of using it in the first place.
      EOF
    end

    def nonced_tag(type, content_or_options, block)
      options = {}
      content = if block
        options = content_or_options
        capture(&block)
      else
        content_or_options.html_safe # :'(
      end
      content_tag type, content, options.merge(nonce: _content_security_policy_nonce(type))
    end

    def extract_options(args)
      if args.last.is_a? Hash
        args.pop
      else
        {}
      end
    end
  end
end

ActiveSupport.on_load :action_view do
  include SecureHeaders::ViewHelpers
end if defined?(ActiveSupport)
