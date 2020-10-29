# frozen_string_literal: true

module Aws
  module Plugins
    # @api private
    class RegionalEndpoint < Seahorse::Client::Plugin
      option(:profile)

      option(:region,
        required: true,
        doc_type: String,
        docstring: <<-DOCS) do |cfg|
The AWS region to connect to.  The configured `:region` is
used to determine the service `:endpoint`. When not passed,
a default `:region` is searched for in the following locations:

* `Aws.config[:region]`
* `ENV['AWS_REGION']`
* `ENV['AMAZON_REGION']`
* `ENV['AWS_DEFAULT_REGION']`
* `~/.aws/credentials`
* `~/.aws/config`
        DOCS
        resolve_region(cfg)
      end

      option(:regional_endpoint, false)

      option(:endpoint, doc_type: String, docstring: <<-DOCS) do |cfg|
The client endpoint is normally constructed from the `:region`
option. You should only configure an `:endpoint` when connecting
to test or custom endpoints. This should be a valid HTTP(S) URI.
        DOCS
        endpoint_prefix = cfg.api.metadata['endpointPrefix']
        if cfg.region && endpoint_prefix
          if cfg.respond_to?(:sts_regional_endpoints)
            sts_regional = cfg.sts_regional_endpoints
          end

          # check region is a valid RFC host label
          unless cfg.region =~ /^(?![0-9]+$)(?!-)[a-zA-Z0-9-]{,63}(?<!-)$/
            raise Errors::InvalidRegionError
          end

          Aws::Partitions::EndpointProvider.resolve(
            cfg.region,
            endpoint_prefix,
            sts_regional
          )
        end
      end

      def after_initialize(client)
        if client.config.region.nil? || client.config.region == ''
          raise Errors::MissingRegionError
        end
      end

      class << self
        private

        def resolve_region(cfg)
          keys = %w[AWS_REGION AMAZON_REGION AWS_DEFAULT_REGION]
          env_region = ENV.values_at(*keys).compact.first
          env_region = nil if env_region == ''
          cfg_region = Aws.shared_config.region(profile: cfg.profile)
          env_region || cfg_region
        end
      end
    end
  end
end
