# frozen_string_literal: true

require 'uri'

module Aws
  module S3
    class Bucket
      # Save the old initialize method so that we can call 'super'.
      old_initialize = instance_method(:initialize)
      # Make the method redefinable
      alias_method :initialize, :initialize
      # Define a new initialize method that extracts out a bucket ARN.
      define_method(:initialize) do |*args|
        old_initialize.bind(self).call(*args)
        bucket_name, region, arn = Plugins::BucketARN.resolve_arn!(
          name,
          client.config.region,
          client.config.s3_use_arn_region
        )
        @name = bucket_name
        @client.config.region = region
        @arn = arn
      end

      # Deletes all objects and versioned objects from this bucket
      #
      # @example
      #
      #   bucket.clear!
      #
      # @return [void]
      def clear!
        object_versions.batch_delete!
      end

      # Deletes all objects and versioned objects from this bucket and
      # then deletes the bucket.
      #
      # @example
      #
      #   bucket.delete!
      #
      # @option options [Integer] :max_attempts (3) Maximum number of times to
      #   attempt to delete the empty bucket before raising
      #   `Aws::S3::Errors::BucketNotEmpty`.
      #
      # @option options [Float] :initial_wait (1.3) Seconds to wait before
      #   retrying the call to delete the bucket, exponentially increased for
      #   each attempt.
      #
      # @return [void]
      def delete!(options = {})
        options = {
          initial_wait: 1.3,
          max_attempts: 3
        }.merge(options)

        attempts = 0
        begin
          clear!
          delete
        rescue Errors::BucketNotEmpty
          attempts += 1
          raise if attempts >= options[:max_attempts]

          Kernel.sleep(options[:initial_wait]**attempts)
          retry
        end
      end

      # Returns a public URL for this bucket.
      #
      # @example
      #
      #   bucket = s3.bucket('bucket-name')
      #   bucket.url
      #   #=> "https://bucket-name.s3.amazonaws.com"
      #
      # It will also work when provided an Access Point ARN.
      #
      # @example
      #
      #   bucket = s3.bucket(
      #     'arn:aws:s3:us-east-1:123456789012:accesspoint:myendpoint'
      #   )
      #   bucket.url
      #   #=> "https://myendpoint-123456789012.s3-accesspoint.us-west-2.amazonaws.com"
      #
      # You can pass `virtual_host: true` to use the bucket name as the
      # host name.
      #
      #     bucket = s3.bucket('my.bucket.com')
      #     bucket.url(virtual_host: true)
      #     #=> "http://my.bucket.com"
      #
      # @option options [Boolean] :virtual_host (false) When `true`,
      #   the bucket name will be used as the host name. This is useful
      #   when you have a CNAME configured for this bucket.
      #
      # @return [String] the URL for this bucket.
      def url(options = {})
        if options[:virtual_host]
          "http://#{name}"
        elsif @arn
          Plugins::BucketARN.resolve_url!(URI.parse(s3_bucket_url), @arn).to_s
        else
          s3_bucket_url
        end
      end

      # Creates a {PresignedPost} that makes it easy to upload a file from
      # a web browser direct to Amazon S3 using an HTML post form with
      # a file field.
      #
      # See the {PresignedPost} documentation for more information.
      # @note You must specify `:key` or `:key_starts_with`. All other options
      #   are optional.
      # @option (see PresignedPost#initialize)
      # @return [PresignedPost]
      # @see PresignedPost
      def presigned_post(options = {})
        PresignedPost.new(
          client.config.credentials,
          client.config.region,
          name,
          { url: url }.merge(options)
        )
      end

      # @api private
      def load
        @data = client.list_buckets.buckets.find { |b| b.name == name }
        raise "unable to load bucket #{name}" if @data.nil?

        self
      end

      private

      def s3_bucket_url
        url = client.config.endpoint.dup
        if bucket_as_hostname?(url.scheme == 'https')
          url.host = "#{name}.#{url.host}"
        else
          url.path += '/' unless url.path[-1] == '/'
          url.path += Seahorse::Util.uri_escape(name)
        end
        if (client.config.region == 'us-east-1') &&
           (client.config.s3_us_east_1_regional_endpoint == 'legacy')
          url.host = Plugins::IADRegionalEndpoint.legacy_host(url.host)
        end
        url.to_s
      end

      def bucket_as_hostname?(https)
        Plugins::BucketDns.dns_compatible?(name, https) &&
          !client.config.force_path_style
      end

    end
  end
end
