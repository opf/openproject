require 'omniauth/strategies/openid_connect'

module OmniAuth
  module OpenIDConnect
    ##
    # A Provider allows the configuration of OpenIDConnect a provider based on
    # a simplified, flat hash.
    #
    # To get the final OmniAuth provider option hash simply use #to_h.
    class Provider
      attr_reader :name, :configuration, :base_redirect_uri, :custom_option_keys

      ##
      # Creates a new provider instance used to configure an OmniAuth provider for
      # the OpenIDConnect strategy.
      #
      # @param name [String] Provider name making it available under
      #                      /auth/<name>/callback by default.
      # @param config [Hash] Hash containing the configuration for this provider as a flat hash.
      # @param base_redirect_uri [String] Base URI for a generated redirect URI in case no explicit
      #                                   configuration is present.
      # @param custom_options [Array] List of symbols declaring custom configuration keys.
      def initialize(name, config,
                     base_redirect_uri: Providers.base_redirect_uri,
                     custom_options: Providers.custom_option_keys)
        @name = name
        @configuration = symbolize_keys config
        @base_redirect_uri = base_redirect_uri
        @custom_option_keys = custom_options
      end

      def to_h
        options
      end

      def options
        opts = {
          name:           name,
          scope:          scope,
          client_options: client_options
        }

        other_options = option_keys
          .map { |key|
            [key, config?(key)]
          }
          .reject { |_, value| value.nil? }

        Hash[other_options]
          .merge(custom_options)
          .merge(opts)
      end

      def client_option_override
        {
          host:         host,
          redirect_uri: redirect_uri
        }
      end

      def custom_options
        entries = custom_option_keys.map do |key|
          name, optional = key.to_s.scan(/^([^\?]+)(\?)?$/).first
          name = name.to_sym
          value = if optional
            config?(name) || try(name)
          else
            config(name)
          end

          [name, value]
        end

        Hash[entries]
      end

      def self.all
        @providers ||= Set.new
      end

      def self.inherited(subclass)
        all << subclass
      end

      def client_options
        entries = client_option_keys
          .map { |key| [key.to_sym, config?(key)] }
          .reject { |_, value| value.nil? }

        # override with configuration
        ensure_client_option_types! Hash[entries].merge(client_option_override)
      end

      def host
        config?(:host) || host_from_endpoint || error_configure(:host)
      end

      def identifier
        config :identifier
      end

      def secret
        config :secret
      end

      def scope
        config?(:scope) || [:openid, :email, :profile]
      end

      ##
      # Path to which to redirect after successful authentication with the provider.
      def redirect_path
        "/auth/#{name}/callback"
      end

      def redirect_uri
        config?(:redirect_uri) || default_redirect_uri || error_configure(:redirect_uri)
      end

      def default_redirect_uri
        base_redirect_uri.gsub(/\/$/, '') + redirect_path if base_redirect_uri
      end

      private

      def ensure_client_option_types!(opts)
        opts[:port] = opts[:port].to_i if opts[:port]
        opts
      end

      def error_configure(name)
        msg = <<-MSG
              Please configure #{name} in the given configuration hash like this:

              #{provider_class_name}.#{self.name}:
                #{name}: <value>
        MSG
        raise ArgumentError, "#{msg.strip}\n"
      end

      def provider_class_name
        Providers.provider_name self.class.name
      end

      ##
      # Returns the configuration value for the given key or nil if it doesn't exist.
      def config?(key)
        self.configuration[key]
      end

      ##
      # Returns the configuration value for the given key or
      # raises an exception if it doesn't exist.
      def config(key)
        configuration[key] || error_configure(key)
      end

      def host_from_endpoint
        begin
          URI.parse(config?(:authorization_endpoint)).host
        rescue URI::InvalidURIError
          nil
        end
      end

      def symbolize_keys(hash)
        entries = hash.map { |key, value| [key.to_s.to_sym, value] }
        Hash[entries]
      end

      def client_option_keys
        Hash(default_options[:client_options]).keys.map(&:to_sym)
      end

      def option_keys
        (default_options.keys - ['client_options']).map(&:to_sym)
      end

      def default_options
        OmniAuth::Strategies::OpenIDConnect.default_options
      end
    end
  end
end
