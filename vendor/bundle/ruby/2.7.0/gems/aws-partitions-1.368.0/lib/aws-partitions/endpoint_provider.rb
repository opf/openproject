# frozen_string_literal: true

module Aws
  module Partitions
    # @api private
    class EndpointProvider
      # When sts_regional_endpoint is set to `legacy`, the endpoint
      # pattern stays global for the following regions:
      STS_LEGACY_REGIONS = %w[
        ap-northeast-1
        ap-south-1
        ap-southeast-1
        ap-southeast-2
        aws-global
        ca-central-1
        eu-central-1
        eu-north-1
        eu-west-1
        eu-west-2
        eu-west-3
        sa-east-1
        us-east-1
        us-east-2
        us-west-1
        us-west-2
      ].freeze

      # Intentionally marked private. The format of the endpoint rules
      # is an implementation detail.
      # @api private
      def initialize(rules)
        @rules = rules
      end

      # @param [String] region The region for the client.
      # @param [String] service The endpoint prefix for the service, e.g.
      #   "monitoring" for cloudwatch.
      # @param [String] sts_regional_endpoints [STS only] Whether to use
      #   `legacy` (global endpoint for legacy regions) or `regional` mode for
      #    using regional endpoint for supported regions except 'aws-global'
      # @api private Use the static class methods instead.
      def resolve(region, service, sts_regional_endpoints)
        'https://' + endpoint_for(region, service, sts_regional_endpoints)
      end

      # @api private Use the static class methods instead.
      def signing_region(region, service)
        get_partition(region)
          .fetch('services', {})
          .fetch(service, {})
          .fetch('endpoints', {})
          .fetch(region, {})
          .fetch('credentialScope', {})
          .fetch('region', region)
      end

      # @api private Use the static class methods instead.
      def dns_suffix_for(region)
        get_partition(region)['dnsSuffix']
      end

      private

      def endpoint_for(region, service, sts_regional_endpoints)
        partition = get_partition(region)
        service_cfg = partition.fetch('services', {}).fetch(service, {})

        # Find the default endpoint
        endpoint = service_cfg
                   .fetch('defaults', {})
                   .fetch('hostname', partition['defaults']['hostname'])

        # Check for sts legacy behavior
        sts_legacy = service == 'sts' &&
                     sts_regional_endpoints == 'legacy' &&
                     STS_LEGACY_REGIONS.include?(region)

        # Check for global endpoint.
        if sts_legacy || service_cfg['isRegionalized'] == false
          region = service_cfg.fetch('partitionEndpoint', region)
        end

        # Check for service/region level endpoint.
        endpoint = service_cfg
                   .fetch('endpoints', {})
                   .fetch(region, {}).fetch('hostname', endpoint)

        # Replace placeholders from the endpoints
        endpoint.sub('{region}', region)
                .sub('{service}', service)
                .sub('{dnsSuffix}', partition['dnsSuffix'])
      end

      def get_partition(region)
        partition_containing_region(region) ||
          partition_matching_region(region) ||
          default_partition
      end

      def partition_containing_region(region)
        @rules['partitions'].find do |p|
          p['regions'].key?(region)
        end
      end

      def partition_matching_region(region)
        @rules['partitions'].find do |p|
          region.match(p['regionRegex']) ||
            p['services'].values.find do |svc|
              svc['endpoints'].key?(region) if svc.key?('endpoints')
            end
        end
      end

      def default_partition
        @rules['partitions'].find { |p| p['partition'] == 'aws' } ||
          @rules['partitions'].first
      end

      class << self
        def resolve(region, service, sts_regional_endpoints = 'regional')
          default_provider.resolve(region, service, sts_regional_endpoints)
        end

        def signing_region(region, service)
          default_provider.signing_region(region, service)
        end

        def dns_suffix_for(region)
          default_provider.dns_suffix_for(region)
        end

        private

        def default_provider
          @default_provider ||= EndpointProvider.new(Partitions.defaults)
        end
      end
    end
  end
end
