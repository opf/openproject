require 'omniauth/openid_connect/providers/version'
require 'omniauth/openid_connect/provider'
require 'logger'

# load pre-defined providers
Dir[File.expand_path('../*.rb', __FILE__)].each do |file|
  require file
end

module OmniAuth
  module OpenIDConnect
    module Providers
      ##
      # Configures certain global provider settings. (optional)
      def self.configure(base_redirect_uri: self.base_redirect_uri,
                         custom_options: self.custom_option_keys)
        self.base_redirect_uri = base_redirect_uri
        self.custom_option_keys = custom_options
      end

      ##
      # Given a configuration hash returns a list of configured providers.
      # The hash is expected to contain one entry for every provider.
      # Provider keys may specify a provider class to be used or omit this to use
      # the default class.
      #
      # Example:
      #
      # { :google => {...}, :test => {...}, 'google.plus' => {...} }
      #
      # =>
      #
      # [
      #   OmniAuth::OpenIDConnect::Google(name=google),
      #   OmniAuth::OpenIDConnect::Provider(name=test),
      #   OmniAuth::OpenIDConnect::Google(name=plus)
      # ]
      #
      # @param config [Hash] Hash containing the configuration for different providers.
      def self.load(config)
        providers = config.map do |key, cfg|
          provider, name = provider_class_and_name key.to_s

          provider.new name, cfg if provider && name
        end

        providers.compact
      end

      ##
      # For the given provider key within a configuration hash
      # this method returns both provider class and name.
      #
      # A provider class can be prepended to a provider name separated by a dot.
      # If a specific provider class can be associated it is returned.
      # Otherwise the default Provider class is used.
      #
      # Examples (with default provider Provider and specific provider Google):
      #
      # 'google'      => Google,   'google'
      # 'google.test' => Google,   'test'
      # 'random'      => Provider, 'random'
      def self.provider_class_and_name(provider_key)
        parts = provider_key.split('.')

        if parts.size == 2                                       # explicit provider class
          class_name = parts.first
          provider_name = parts.last
          provider_class = find_provider_class class_name

          [provider_class, provider_name]
        elsif provider_class = find_provider_class(provider_key) # provider class == name
          [provider_class, provider_key]
        elsif parts.size == 1                                    # implicit default provider class
          [OmniAuth::OpenIDConnect::Provider, provider_key]
        else
          logger.warn "Skipping invalid provider key: #{provider_key}"

          []
        end
      end

      def self.find_provider_class(name)
        Provider.all.detect { |cl| provider_name(cl.name) == name }
      end

      def self.provider_name(class_name)
        class_name.split('::').last.downcase
      end

      ##
      # Sets custom options that may be configured for a provider.
      # If a key ends with a '?' it is optional, otherwise it is required.
      #
      # Example:
      #
      #     # Enable custom options. Display name is required and icon is optional.
      #     Provider.custom_options = [:display_name, :icon?]
      #
      # @param keys [Array] List of symbols indicating required or optional custom options.
      def self.custom_option_keys=(keys)
        @custom_option_keys = keys
      end

      def self.custom_option_keys
        @custom_option_keys ||= []
      end

      def self.base_redirect_uri=(uri)
        @base_redirect_uri = uri
      end

      def self.base_redirect_uri
        @base_redirect_uri
      end

      def self.logger
        @logger ||= Logger.new(STDOUT)
      end

      def self.logger=(logger)
        @logger = logger
      end
    end
  end
end
