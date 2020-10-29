# frozen_string_literal: true

module Aws
  module S3
    module Plugins
      # Provides support for using `Aws::S3::Client` with Amazon S3 Transfer
      # Acceleration.
      #
      # Go here for more information about transfer acceleration:
      # [http://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html](http://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html)
      class Accelerate < Seahorse::Client::Plugin
        option(
          :use_accelerate_endpoint,
          default: false,
          doc_type: 'Boolean',
          docstring: <<-DOCS)
When set to `true`, accelerated bucket endpoints will be used
for all object operations. You must first enable accelerate for
each bucket. [Go here for more information](http://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html).
          DOCS

        def add_handlers(handlers, config)
          operations = config.api.operation_names - [
            :create_bucket, :list_buckets, :delete_bucket
          ]
          # Need 2 handlers so that the context can be set for other plugins
          # and to remove :use_accelerate_endpoint from the params.
          handlers.add(
            OptionHandler, step: :initialize, operations: operations
          )
          handlers.add(
            AccelerateHandler, step: :build, priority: 0, operations: operations
          )
        end

        # @api private
        class OptionHandler < Seahorse::Client::Handler
          def call(context)
            # Support client configuration and per-operation configuration
            if context.params.is_a?(Hash)
              accelerate = context.params.delete(:use_accelerate_endpoint)
            end
            if accelerate.nil?
              accelerate = context.config.use_accelerate_endpoint
            end
            context[:use_accelerate_endpoint] = accelerate
            @handler.call(context)
          end
        end

        # @api private
        class AccelerateHandler < Seahorse::Client::Handler
          def call(context)
            if context[:use_accelerate_endpoint]
              dualstack = !!context[:use_dualstack_endpoint]
              use_accelerate_endpoint(context, dualstack)
            end
            @handler.call(context)
          end

          private

          def use_accelerate_endpoint(context, dualstack)
            bucket_name = context.params[:bucket]
            validate_bucket_name!(bucket_name)
            endpoint = URI.parse(context.http_request.endpoint.to_s)
            endpoint.scheme = 'https'
            endpoint.port = 443
            endpoint.host = "#{bucket_name}.s3-accelerate"\
                            "#{'.dualstack' if dualstack}.amazonaws.com"
            context.http_request.endpoint = endpoint.to_s
            # s3 accelerate endpoint doesn't work with 'expect' header
            context.http_request.headers.delete('expect')
          end

          def validate_bucket_name!(bucket_name)
            unless BucketDns.dns_compatible?(bucket_name, _ssl = true)
              raise ArgumentError,
                    'Unable to use `use_accelerate_endpoint: true` on buckets '\
                    'with non-DNS compatible names.'
            end
          end
        end
      end
    end
  end
end
