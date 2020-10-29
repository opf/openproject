# frozen_string_literal: true

require "set"

module SecureHeaders
  module PolicyManagement
    def self.included(base)
      base.extend(ClassMethods)
    end

    DEFAULT_CONFIG = {
      default_src: %w(https:),
      img_src: %w(https: data: 'self'),
      object_src: %w('none'),
      script_src: %w(https:),
      style_src: %w('self' 'unsafe-inline' https:),
      form_action: %w('self')
    }.freeze
    DATA_PROTOCOL = "data:".freeze
    BLOB_PROTOCOL = "blob:".freeze
    SELF = "'self'".freeze
    NONE = "'none'".freeze
    STAR = "*".freeze
    UNSAFE_INLINE = "'unsafe-inline'".freeze
    UNSAFE_EVAL = "'unsafe-eval'".freeze
    STRICT_DYNAMIC = "'strict-dynamic'".freeze

    # leftover deprecated values that will be in common use upon upgrading.
    DEPRECATED_SOURCE_VALUES = [SELF, NONE, UNSAFE_EVAL, UNSAFE_INLINE, "inline", "eval"].map { |value| value.delete("'") }.freeze

    DEFAULT_SRC = :default_src
    CONNECT_SRC = :connect_src
    FONT_SRC = :font_src
    FRAME_SRC = :frame_src
    IMG_SRC = :img_src
    MEDIA_SRC = :media_src
    OBJECT_SRC = :object_src
    SANDBOX = :sandbox
    SCRIPT_SRC = :script_src
    STYLE_SRC = :style_src
    REPORT_URI = :report_uri

    DIRECTIVES_1_0 = [
      DEFAULT_SRC,
      CONNECT_SRC,
      FONT_SRC,
      FRAME_SRC,
      IMG_SRC,
      MEDIA_SRC,
      OBJECT_SRC,
      SANDBOX,
      SCRIPT_SRC,
      STYLE_SRC,
      REPORT_URI
    ].freeze

    BASE_URI = :base_uri
    CHILD_SRC = :child_src
    FORM_ACTION = :form_action
    FRAME_ANCESTORS = :frame_ancestors
    PLUGIN_TYPES = :plugin_types

    DIRECTIVES_2_0 = [
      DIRECTIVES_1_0,
      BASE_URI,
      CHILD_SRC,
      FORM_ACTION,
      FRAME_ANCESTORS,
      PLUGIN_TYPES
    ].flatten.freeze

    # All the directives currently under consideration for CSP level 3.
    # https://w3c.github.io/webappsec/specs/CSP2/
    BLOCK_ALL_MIXED_CONTENT = :block_all_mixed_content
    MANIFEST_SRC = :manifest_src
    NAVIGATE_TO = :navigate_to
    PREFETCH_SRC = :prefetch_src
    REQUIRE_SRI_FOR = :require_sri_for
    UPGRADE_INSECURE_REQUESTS = :upgrade_insecure_requests
    WORKER_SRC = :worker_src

    DIRECTIVES_3_0 = [
      DIRECTIVES_2_0,
      BLOCK_ALL_MIXED_CONTENT,
      MANIFEST_SRC,
      NAVIGATE_TO,
      PREFETCH_SRC,
      REQUIRE_SRI_FOR,
      WORKER_SRC,
      UPGRADE_INSECURE_REQUESTS
    ].flatten.freeze

    ALL_DIRECTIVES = (DIRECTIVES_1_0 + DIRECTIVES_2_0 + DIRECTIVES_3_0).uniq.sort

    # Think of default-src and report-uri as the beginning and end respectively,
    # everything else is in between.
    BODY_DIRECTIVES = ALL_DIRECTIVES - [DEFAULT_SRC, REPORT_URI]

    DIRECTIVE_VALUE_TYPES = {
      BASE_URI                  => :source_list,
      BLOCK_ALL_MIXED_CONTENT   => :boolean,
      CHILD_SRC                 => :source_list,
      CONNECT_SRC               => :source_list,
      DEFAULT_SRC               => :source_list,
      FONT_SRC                  => :source_list,
      FORM_ACTION               => :source_list,
      FRAME_ANCESTORS           => :source_list,
      FRAME_SRC                 => :source_list,
      IMG_SRC                   => :source_list,
      MANIFEST_SRC              => :source_list,
      MEDIA_SRC                 => :source_list,
      NAVIGATE_TO               => :source_list,
      OBJECT_SRC                => :source_list,
      PLUGIN_TYPES              => :media_type_list,
      REQUIRE_SRI_FOR           => :require_sri_for_list,
      REPORT_URI                => :source_list,
      PREFETCH_SRC              => :source_list,
      SANDBOX                   => :sandbox_list,
      SCRIPT_SRC                => :source_list,
      STYLE_SRC                 => :source_list,
      WORKER_SRC                => :source_list,
      UPGRADE_INSECURE_REQUESTS => :boolean,
    }.freeze

    # These are directives that don't have use a source list, and hence do not
    # inherit the default-src value.
    NON_SOURCE_LIST_SOURCES = DIRECTIVE_VALUE_TYPES.select do |_, type|
      type != :source_list
    end.keys.freeze

    # These are directives that take a source list, but that do not inherit
    # the default-src value.
    NON_FETCH_SOURCES = [
      BASE_URI,
      FORM_ACTION,
      FRAME_ANCESTORS,
      NAVIGATE_TO,
      REPORT_URI,
    ]

    FETCH_SOURCES = ALL_DIRECTIVES - NON_FETCH_SOURCES - NON_SOURCE_LIST_SOURCES

    STAR_REGEXP = Regexp.new(Regexp.escape(STAR))
    HTTP_SCHEME_REGEX = %r{\Ahttps?://}

    WILDCARD_SOURCES = [
      UNSAFE_EVAL,
      UNSAFE_INLINE,
      STAR,
      DATA_PROTOCOL,
      BLOB_PROTOCOL
    ].freeze

    META_CONFIGS = [
      :report_only,
      :preserve_schemes,
      :disable_nonce_backwards_compatibility
    ].freeze

    NONCES = [
      :script_nonce,
      :style_nonce
    ].freeze

    REQUIRE_SRI_FOR_VALUES = Set.new(%w(script style))

    module ClassMethods
      # Public: generate a header name, value array that is user-agent-aware.
      #
      # Returns a default policy if no configuration is provided, or a
      # header name and value based on the config.
      def make_header(config)
        return if config.nil? || config == OPT_OUT
        header = new(config)
        [header.name, header.value]
      end

      # Public: Validates each source expression.
      #
      # Does not validate the invididual values of the source expression (e.g.
      # script_src => h*t*t*p: will not raise an exception)
      def validate_config!(config)
        return if config.nil? || config.opt_out?
        raise ContentSecurityPolicyConfigError.new(":default_src is required") unless config.directive_value(:default_src)
        if config.directive_value(:script_src).nil?
          raise ContentSecurityPolicyConfigError.new(":script_src is required, falling back to default-src is too dangerous. Use `script_src: OPT_OUT` to override")
        end
        if !config.report_only? && config.directive_value(:report_only)
          raise ContentSecurityPolicyConfigError.new("Only the csp_report_only config should set :report_only to true")
        end

        if config.report_only? && config.directive_value(:report_only) == false
          raise ContentSecurityPolicyConfigError.new("csp_report_only config must have :report_only set to true")
        end

        ContentSecurityPolicyConfig.attrs.each do |key|
          value = config.directive_value(key)
          next unless value

          if META_CONFIGS.include?(key)
            raise ContentSecurityPolicyConfigError.new("#{key} must be a boolean value") unless boolean?(value) || value.nil?
          elsif NONCES.include?(key)
            raise ContentSecurityPolicyConfigError.new("#{key} must be a non-nil value") if value.nil?
          else
            validate_directive!(key, value)
          end
        end
      end

      # Public: combine the values from two different configs.
      #
      # original - the main config
      # additions - values to be merged in
      #
      # raises an error if the original config is OPT_OUT
      #
      # 1. for non-source-list values (report_only, block_all_mixed_content, upgrade_insecure_requests),
      # additions will overwrite the original value.
      # 2. if a value in additions does not exist in the original config, the
      # default-src value is included to match original behavior.
      # 3. if a value in additions does exist in the original config, the two
      # values are joined.
      def combine_policies(original, additions)
        if original == {}
          raise ContentSecurityPolicyConfigError.new("Attempted to override an opt-out CSP config.")
        end

        original = Configuration.send(:deep_copy, original)
        populate_fetch_source_with_default!(original, additions)
        merge_policy_additions(original, additions)
      end

      def ua_to_variation(user_agent)
        family = user_agent.browser
        if family && VARIATIONS.key?(family)
          family
        else
          OTHER
        end
      end

      private

      # merge the two hashes. combine (instead of overwrite) the array values
      # when each hash contains a value for a given key.
      def merge_policy_additions(original, additions)
        original.merge(additions) do |directive, lhs, rhs|
          if list_directive?(directive)
            (lhs.to_a + rhs.to_a).compact.uniq
          else
            rhs
          end
        end.reject { |_, value| value.nil? || value == [] } # this mess prevents us from adding empty directives.
      end

      # Returns True if a directive expects a list of values and False otherwise.
      def list_directive?(directive)
        source_list?(directive) ||
          sandbox_list?(directive) ||
          media_type_list?(directive) ||
          require_sri_for_list?(directive)
      end

      # For each directive in additions that does not exist in the original config,
      # copy the default-src value to the original config. This modifies the original hash.
      def populate_fetch_source_with_default!(original, additions)
        # in case we would be appending to an empty directive, fill it with the default-src value
        additions.each_key do |directive|
          directive = if directive.to_s.end_with?("_nonce")
            directive.to_s.gsub(/_nonce/, "_src").to_sym
          else
            directive
          end
          # Don't set a default if directive has an existing value
          next if original[directive]
          if FETCH_SOURCES.include?(directive)
            original[directive] = original[DEFAULT_SRC]
          end
        end
      end

      def source_list?(directive)
        DIRECTIVE_VALUE_TYPES[directive] == :source_list
      end

      def sandbox_list?(directive)
        DIRECTIVE_VALUE_TYPES[directive] == :sandbox_list
      end

      def media_type_list?(directive)
        DIRECTIVE_VALUE_TYPES[directive] == :media_type_list
      end

      def require_sri_for_list?(directive)
        DIRECTIVE_VALUE_TYPES[directive] == :require_sri_for_list
      end

      # Private: Validates that the configuration has a valid type, or that it is a valid
      # source expression.
      def validate_directive!(directive, value)
        ensure_valid_directive!(directive)
        case ContentSecurityPolicy::DIRECTIVE_VALUE_TYPES[directive]
        when :source_list
          validate_source_expression!(directive, value)
        when :boolean
          unless boolean?(value)
            raise ContentSecurityPolicyConfigError.new("#{directive} must be a boolean. Found #{value.class} value")
          end
        when :sandbox_list
          validate_sandbox_expression!(directive, value)
        when :media_type_list
          validate_media_type_expression!(directive, value)
        when :require_sri_for_list
          validate_require_sri_source_expression!(directive, value)
        else
          raise ContentSecurityPolicyConfigError.new("Unknown directive #{directive}")
        end
      end

      # Private: validates that a sandbox token expression:
      # 1. is an array of strings or optionally `true` (to enable maximal sandboxing)
      # 2. For arrays, each element is of the form allow-*
      def validate_sandbox_expression!(directive, sandbox_token_expression)
        # We support sandbox: true to indicate a maximally secure sandbox.
        return if boolean?(sandbox_token_expression) && sandbox_token_expression == true
        ensure_array_of_strings!(directive, sandbox_token_expression)
        valid = sandbox_token_expression.compact.all? do |v|
          v.is_a?(String) && v.start_with?("allow-")
        end
        if !valid
          raise ContentSecurityPolicyConfigError.new("#{directive} must be True or an array of zero or more sandbox token strings (ex. allow-forms)")
        end
      end

      # Private: validates that a media type expression:
      # 1. is an array of strings
      # 2. each element is of the form type/subtype
      def validate_media_type_expression!(directive, media_type_expression)
        ensure_array_of_strings!(directive, media_type_expression)
        valid = media_type_expression.compact.all? do |v|
          # All media types are of the form: <type from RFC 2045> "/" <subtype from RFC 2045>.
          v =~ /\A.+\/.+\z/
        end
        if !valid
          raise ContentSecurityPolicyConfigError.new("#{directive} must be an array of valid media types (ex. application/pdf)")
        end
      end

      # Private: validates that a require sri for expression:
      # 1. is an array of strings
      # 2. is a subset of ["string", "style"]
      def validate_require_sri_source_expression!(directive, require_sri_for_expression)
        ensure_array_of_strings!(directive, require_sri_for_expression)
        unless require_sri_for_expression.to_set.subset?(REQUIRE_SRI_FOR_VALUES)
          raise ContentSecurityPolicyConfigError.new(%(require-sri for must be a subset of #{REQUIRE_SRI_FOR_VALUES.to_a} but was #{require_sri_for_expression}))
        end
      end

      # Private: validates that a source expression:
      # 1. is an array of strings
      # 2. does not contain any deprecated, now invalid values (inline, eval, self, none)
      #
      # Does not validate the invididual values of the source expression (e.g.
      # script_src => h*t*t*p: will not raise an exception)
      def validate_source_expression!(directive, source_expression)
        if source_expression != OPT_OUT
          ensure_array_of_strings!(directive, source_expression)
        end
        ensure_valid_sources!(directive, source_expression)
      end

      def ensure_valid_directive!(directive)
        unless ContentSecurityPolicy::ALL_DIRECTIVES.include?(directive)
          raise ContentSecurityPolicyConfigError.new("Unknown directive #{directive}")
        end
      end

      def ensure_array_of_strings!(directive, value)
        if (!value.is_a?(Array) || !value.compact.all? { |v| v.is_a?(String) })
          raise ContentSecurityPolicyConfigError.new("#{directive} must be an array of strings")
        end
      end

      def ensure_valid_sources!(directive, source_expression)
        return if source_expression == OPT_OUT
        source_expression.each do |expression|
          if ContentSecurityPolicy::DEPRECATED_SOURCE_VALUES.include?(expression)
            raise ContentSecurityPolicyConfigError.new("#{directive} contains an invalid keyword source (#{expression}). This value must be single quoted.")
          end
        end
      end

      def boolean?(source_expression)
        source_expression.is_a?(TrueClass) || source_expression.is_a?(FalseClass)
      end
    end
  end
end
