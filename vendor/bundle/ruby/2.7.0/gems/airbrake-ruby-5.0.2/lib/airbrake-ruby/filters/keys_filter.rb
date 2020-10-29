module Airbrake
  # Namespace for all standard filters. Custom filters can also go under this
  # namespace.
  module Filters
    # This is a filter helper that endows a class ability to filter notices'
    # payload based on the return value of the +should_filter?+ method that a
    # class that includes this module must implement.
    #
    # @see Notice
    # @see KeysAllowlist
    # @see KeysBlocklist
    # @api private
    module KeysFilter
      # @return [String] The label to replace real values of filtered payload
      FILTERED = '[Filtered]'.freeze

      # @return [Array<String,Symbol,Regexp>] the array of classes instances of
      #   which can compared with payload keys
      VALID_PATTERN_CLASSES = [String, Symbol, Regexp].freeze

      # @return [Array<Symbol>] parts of a Notice's payload that can be modified
      #   by blocklist/allowlist filters
      FILTERABLE_KEYS = %i[environment session params].freeze

      # @return [Array<Symbol>] parts of a Notice's *context* payload that can
      #   be modified by blocklist/allowlist filters
      FILTERABLE_CONTEXT_KEYS = %i[
        user

        # Provided by Airbrake::Rack::HttpHeadersFilter
        headers
        referer
        httpMethod

        # Provided by Airbrake::Rack::ContextFilter
        userAddr
        userAgent
      ].freeze

      include Loggable

      # @return [Integer]
      attr_reader :weight

      # Creates a new KeysBlocklist or KeysAllowlist filter that uses the given
      # +patterns+ for filtering a notice's payload.
      #
      # @param [Array<String,Regexp,Symbol>] patterns
      def initialize(patterns)
        @patterns = patterns
        @valid_patterns = false
      end

      # @!macro call_filter
      #   This is a mandatory method required by any filter integrated with
      #   FilterChain.
      #
      #   @param [Notice] notice the notice to be filtered
      #   @return [void]
      #   @see FilterChain
      def call(notice)
        unless @valid_patterns
          eval_proc_patterns!
          validate_patterns
        end

        FILTERABLE_KEYS.each do |key|
          notice[key] = filter_hash(notice[key])
        end

        FILTERABLE_CONTEXT_KEYS.each { |key| filter_context_key(notice, key) }

        return unless notice[:context][:url]

        filter_url(notice)
      end

      # @raise [NotImplementedError] if called directly
      def should_filter?(_key)
        raise NotImplementedError, 'method must be implemented in the included class'
      end

      private

      def filter_hash(hash)
        return hash unless hash.is_a?(Hash)

        hash_copy = hash.dup

        hash.each_key do |key|
          if should_filter?(key.to_s)
            hash_copy[key] = FILTERED
          elsif hash_copy[key].is_a?(Hash)
            hash_copy[key] = filter_hash(hash_copy[key])
          elsif hash[key].is_a?(Array)
            hash_copy[key].each_with_index do |h, i|
              hash_copy[key][i] = filter_hash(h)
            end
          end
        end

        hash_copy
      end

      def filter_url_params(url)
        url.query = Hash[URI.decode_www_form(url.query)].map do |key, val|
          should_filter?(key) ? "#{key}=[Filtered]" : "#{key}=#{val}"
        end.join('&')

        url.to_s
      end

      def filter_url(notice)
        begin
          url = URI(notice[:context][:url])
        rescue URI::InvalidURIError
          return
        end

        return unless url.query

        notice[:context][:url] = filter_url_params(url)
      end

      def eval_proc_patterns!
        return unless @patterns.any? { |pattern| pattern.is_a?(Proc) }

        @patterns = @patterns.flat_map do |pattern|
          next(pattern) unless pattern.respond_to?(:call)

          pattern.call
        end
      end

      def validate_patterns
        @valid_patterns = @patterns.all? do |pattern|
          VALID_PATTERN_CLASSES.any? { |c| pattern.is_a?(c) }
        end

        return if @valid_patterns

        logger.error(
          "#{LOG_LABEL} one of the patterns in #{self.class} is invalid. " \
          "Known patterns: #{@patterns}",
        )
      end

      def filter_context_key(notice, key)
        return unless notice[:context][key]
        return if notice[:context][key] == FILTERED
        unless should_filter?(key)
          return notice[:context][key] = filter_hash(notice[:context][key])
        end

        notice[:context][key] = FILTERED
      end
    end
  end
end
