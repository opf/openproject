# frozen_string_literal: true

module Aws
  module S3
    module Plugins
      # When an accesspoint ARN is provided for :bucket in S3 operations, this
      # plugin resolves the request endpoint from the ARN when possible.
      class BucketARN < Seahorse::Client::Plugin
        option(
          :s3_use_arn_region,
          default: true,
          doc_type: 'Boolean',
          docstring: <<-DOCS) do |cfg|
By default, the SDK will use the S3 ARN region, and cross-region
requests could be made. Set to `false` to not use the region from
the S3 ARN.
          DOCS
          resolve_s3_use_arn_region(cfg)
        end

        def add_handlers(handlers, _config)
          handlers.add(Handler)
        end

        # @api private
        class Handler < Seahorse::Client::Handler
          def call(context)
            bucket_member = _bucket_member(context.operation.input.shape)
            if bucket_member && (bucket = context.params[bucket_member])
              _resolved_bucket, _resolved_region, arn = BucketARN.resolve_arn!(
                bucket,
                context.config.region,
                context.config.s3_use_arn_region
              )
              if arn
                if arn.resource.start_with?('accesspoint')
                  validate_config!(context.config)
                end

                dualstack = extract_dualstack_config!(context)

                BucketARN.resolve_url!(
                  context.http_request.endpoint,
                  arn,
                  dualstack
                )
              end
            end
            @handler.call(context)
          end

          private

          def _bucket_member(input)
            input.members.each do |member, ref|
              return member if ref.shape.name == 'BucketName'
            end
            nil
          end

          # other plugins use dualstack so disable it when we're done
          def extract_dualstack_config!(context)
            dualstack = context[:use_dualstack_endpoint]
            context[:use_dualstack_endpoint] = false if dualstack
            dualstack
          end

          def validate_config!(config)
            unless config.regional_endpoint
              raise ArgumentError,
                'Cannot provide both an accesspoint ARN and :endpoint.'
            end

            if config.use_accelerate_endpoint
              raise ArgumentError,
                'Cannot provide both an accesspoint ARN and setting '\
                ':use_accelerate_endpoint to true.'
            end

            if config.force_path_style
              raise ArgumentError,
                'Cannot provide both an accesspoint ARN and setting '\
                ':force_path_style to true.'
            end
          end
        end

        class << self

          # @api private
          def resolve_arn!(bucket_name, region, s3_use_arn_region)
            if Aws::ARNParser.arn?(bucket_name)
              arn = Aws::ARNParser.parse(bucket_name)
              validate_s3_arn!(arn)
              validate_region!(arn, region, s3_use_arn_region)
              if arn.resource.start_with?('accesspoint')
                region = arn.region if s3_use_arn_region
                [bucket_name, region, arn]
              else
                raise ArgumentError,
                  'Only accesspoint type ARNs are currently supported.'
              end
            else
              [bucket_name, region]
            end
          end

          # @api private
          def resolve_url!(url, arn, dualstack = false)
            if arn.resource.start_with?('accesspoint')
              url.host = accesspoint_arn_host(arn, dualstack)
            else
              raise ArgumentError,
                'Only accesspoint type ARNs are currently supported.'
            end
            url.path = url_path(url.path, arn)
            url
          end

          private

          def accesspoint_arn_host(arn, dualstack)
            _resource_type, resource_name = parse_resource(arn.resource)
            sfx = Aws::Partitions::EndpointProvider.dns_suffix_for(arn.region)
            "#{resource_name}-#{arn.account_id}"\
            '.s3-accesspoint'\
            "#{'.dualstack' if dualstack}"\
            ".#{arn.region}.#{sfx}"
          end

          def parse_resource(str)
            slash = str.index('/') || str.length
            colon = str.index(':') || str.length
            delimiter = slash < colon ? slash : colon
            if delimiter < str.length
              [str[0..(delimiter - 1)], str[(delimiter + 1)..-1]]
            else
              [nil, str]
            end
          end

          def resolve_s3_use_arn_region(cfg)
            value = ENV['AWS_S3_USE_ARN_REGION'] ||
                    Aws.shared_config.s3_use_arn_region(profile: cfg.profile) ||
                    'true'

            # Raise if provided value is not true or false
            if value != 'true' && value != 'false'
              raise ArgumentError,
                'Must provide either `true` or `false` for '\
                's3_use_arn_region profile option or for '\
                'ENV[\'AWS_S3_USE_ARN_REGION\']'
            end

            value == 'true'
          end

          def url_path(path, arn)
            path = path.sub("/#{Seahorse::Util.uri_escape(arn.to_s)}", '')
                       .sub("/#{arn}", '')
            "/#{path}" unless path.match(/^\//)
            path
          end

          def validate_s3_arn!(arn)
            _resource_type, resource_name = parse_resource(arn.resource)

            unless arn.service == 's3'
              raise ArgumentError, 'Must provide an S3 ARN.'
            end

            if arn.region.empty? || arn.account_id.empty?
              raise ArgumentError,
                'S3 Access Point ARNs must contain both a valid region '\
                ' and a valid account id.'
            end

            if resource_name.include?(':') || resource_name.include?('/')
              raise ArgumentError,
                'ARN resource id must be a single value.'
            end

            unless Plugins::BucketDns.valid_subdomain?(
              "#{resource_name}-#{arn.account_id}"
            )
              raise ArgumentError,
                "#{resource_name}-#{arn.account_id} is not a "\
                'valid subdomain.'
            end
          end

          def validate_region!(arn, region, s3_use_arn_region)
            if region.include?('fips')
              raise ArgumentError,
                'FIPS client regions are currently not supported with '\
                'accesspoint ARNs.'
            end

            if s3_use_arn_region &&
               !Aws::Partitions.partition(arn.partition).region?(region)
              raise Aws::Errors::InvalidARNPartitionError
            end

            if !s3_use_arn_region && region != arn.region
              raise Aws::Errors::InvalidARNRegionError
            end
          end
        end
      end
    end
  end
end
