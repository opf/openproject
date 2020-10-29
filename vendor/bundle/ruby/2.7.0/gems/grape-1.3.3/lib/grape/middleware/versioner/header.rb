# frozen_string_literal: true

require 'grape/middleware/base'
require 'grape/middleware/versioner/parse_media_type_patch'

module Grape
  module Middleware
    module Versioner
      # This middleware sets various version related rack environment variables
      # based on the HTTP Accept header with the pattern:
      # application/vnd.:vendor-:version+:format
      #
      # Example: For request header
      #    Accept: application/vnd.mycompany.a-cool-resource-v1+json
      #
      # The following rack env variables are set:
      #
      #    env['api.type']    => 'application'
      #    env['api.subtype'] => 'vnd.mycompany.a-cool-resource-v1+json'
      #    env['api.vendor]   => 'mycompany.a-cool-resource'
      #    env['api.version]  => 'v1'
      #    env['api.format]   => 'json'
      #
      # If version does not match this route, then a 406 is raised with
      # X-Cascade header to alert Grape::Router to attempt the next matched
      # route.
      class Header < Base
        VENDOR_VERSION_HEADER_REGEX =
          /\Avnd\.([a-z0-9.\-_!#\$&\^]+?)(?:-([a-z0-9*.]+))?(?:\+([a-z0-9*\-.]+))?\z/.freeze

        HAS_VENDOR_REGEX = /\Avnd\.[a-z0-9.\-_!#\$&\^]+/.freeze
        HAS_VERSION_REGEX = /\Avnd\.([a-z0-9.\-_!#\$&\^]+?)(?:-([a-z0-9*.]+))+/.freeze

        def before
          strict_header_checks if strict?

          if media_type || env[Grape::Env::GRAPE_ALLOWED_METHODS]
            media_type_header_handler
          elsif headers_contain_wrong_vendor?
            fail_with_invalid_accept_header!('API vendor not found.')
          elsif headers_contain_wrong_version?
            fail_with_invalid_version_header!('API version not found.')
          end
        end

        private

        def strict_header_checks
          strict_accept_header_presence_check
          strict_version_vendor_accept_header_presence_check
        end

        def strict_accept_header_presence_check
          return unless header.qvalues.empty?
          fail_with_invalid_accept_header!('Accept header must be set.')
        end

        def strict_version_vendor_accept_header_presence_check
          return unless versions.present?
          return if an_accept_header_with_version_and_vendor_is_present?
          fail_with_invalid_accept_header!('API vendor or version not found.')
        end

        def an_accept_header_with_version_and_vendor_is_present?
          header.qvalues.keys.any? do |h|
            VENDOR_VERSION_HEADER_REGEX.match?(h.sub('application/', ''))
          end
        end

        def header
          @header ||= rack_accept_header
        end

        def media_type
          @media_type ||= header.best_of(available_media_types)
        end

        def media_type_header_handler
          type, subtype = Rack::Accept::Header.parse_media_type(media_type)
          env[Grape::Env::API_TYPE] = type
          env[Grape::Env::API_SUBTYPE] = subtype

          return unless VENDOR_VERSION_HEADER_REGEX =~ subtype

          env[Grape::Env::API_VENDOR] = Regexp.last_match[1]
          env[Grape::Env::API_VERSION] = Regexp.last_match[2]
          # weird that Grape::Middleware::Formatter also does this
          env[Grape::Env::API_FORMAT] = Regexp.last_match[3]
        end

        def fail_with_invalid_accept_header!(message)
          raise Grape::Exceptions::InvalidAcceptHeader
            .new(message, error_headers)
        end

        def fail_with_invalid_version_header!(message)
          raise Grape::Exceptions::InvalidVersionHeader
            .new(message, error_headers)
        end

        def available_media_types
          available_media_types = []

          content_types.each_key do |extension|
            versions.reverse_each do |version|
              available_media_types += [
                "application/vnd.#{vendor}-#{version}+#{extension}",
                "application/vnd.#{vendor}-#{version}"
              ]
            end
            available_media_types << "application/vnd.#{vendor}+#{extension}"
          end

          available_media_types << "application/vnd.#{vendor}"

          content_types.each_value do |media_type|
            available_media_types << media_type
          end

          available_media_types.flatten
        end

        def headers_contain_wrong_vendor?
          header.values.all? do |header_value|
            vendor?(header_value) && request_vendor(header_value) != vendor
          end
        end

        def headers_contain_wrong_version?
          header.values.all? do |header_value|
            version?(header_value) && !versions.include?(request_version(header_value))
          end
        end

        def rack_accept_header
          Rack::Accept::MediaType.new env[Grape::Http::Headers::HTTP_ACCEPT]
        rescue RuntimeError => e
          fail_with_invalid_accept_header!(e.message)
        end

        def versions
          options[:versions] || []
        end

        def vendor
          version_options && version_options[:vendor]
        end

        def strict?
          version_options && version_options[:strict]
        end

        def version_options
          options[:version_options]
        end

        # By default those errors contain an `X-Cascade` header set to `pass`,
        # which allows nesting and stacking of routes
        # (see Grape::Router for more
        # information). To prevent # this behavior, and not add the `X-Cascade`
        # header, one can set the `:cascade` option to `false`.
        def cascade?
          if version_options && version_options.key?(:cascade)
            version_options[:cascade]
          else
            true
          end
        end

        def error_headers
          cascade? ? { Grape::Http::Headers::X_CASCADE => 'pass' } : {}
        end

        # @param [String] media_type a content type
        # @return [Boolean] whether the content type sets a vendor
        def vendor?(media_type)
          _, subtype = Rack::Accept::Header.parse_media_type(media_type)
          subtype.present? && subtype[HAS_VENDOR_REGEX]
        end

        def request_vendor(media_type)
          _, subtype = Rack::Accept::Header.parse_media_type(media_type)
          subtype.match(VENDOR_VERSION_HEADER_REGEX)[1]
        end

        def request_version(media_type)
          _, subtype = Rack::Accept::Header.parse_media_type(media_type)
          subtype.match(VENDOR_VERSION_HEADER_REGEX)[2]
        end

        # @param [String] media_type a content type
        # @return [Boolean] whether the content type sets an API version
        def version?(media_type)
          _, subtype = Rack::Accept::Header.parse_media_type(media_type)
          subtype.present? && subtype[HAS_VERSION_REGEX]
        end
      end
    end
  end
end
