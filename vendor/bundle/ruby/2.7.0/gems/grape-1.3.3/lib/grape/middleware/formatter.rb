# frozen_string_literal: true

require 'grape/middleware/base'

module Grape
  module Middleware
    class Formatter < Base
      CHUNKED = 'chunked'

      def default_options
        {
          default_format: :txt,
          formatters: {},
          parsers: {}
        }
      end

      def before
        negotiate_content_type
        read_body_input
      end

      def after
        return unless @app_response
        status, headers, bodies = *@app_response

        if Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include?(status)
          @app_response
        else
          build_formatted_response(status, headers, bodies)
        end
      end

      private

      def build_formatted_response(status, headers, bodies)
        headers = ensure_content_type(headers)

        if bodies.is_a?(Grape::ServeFile::FileResponse)
          Grape::ServeFile::SendfileResponse.new([], status, headers) do |resp|
            resp.body = bodies.file
          end
        else
          # Allow content-type to be explicitly overwritten
          formatter = fetch_formatter(headers, options)
          bodymap = ActiveSupport::Notifications.instrument('format_response.grape', formatter: formatter, env: env) do
            bodies.collect { |body| formatter.call(body, env) }
          end
          Rack::Response.new(bodymap, status, headers)
        end
      rescue Grape::Exceptions::InvalidFormatter => e
        throw :error, status: 500, message: e.message, backtrace: e.backtrace, original_exception: e
      end

      def fetch_formatter(headers, options)
        api_format = mime_types[headers[Grape::Http::Headers::CONTENT_TYPE]] || env[Grape::Env::API_FORMAT]
        Grape::Formatter.formatter_for(api_format, **options)
      end

      # Set the content type header for the API format if it is not already present.
      #
      # @param headers [Hash]
      # @return [Hash]
      def ensure_content_type(headers)
        if headers[Grape::Http::Headers::CONTENT_TYPE]
          headers
        else
          headers.merge(Grape::Http::Headers::CONTENT_TYPE => content_type_for(env[Grape::Env::API_FORMAT]))
        end
      end

      def request
        @request ||= Rack::Request.new(env)
      end

      # store read input in env['api.request.input']
      def read_body_input
        return unless
          (request.post? || request.put? || request.patch? || request.delete?) &&
          (!request.form_data? || !request.media_type) &&
          !request.parseable_data? &&
          (request.content_length.to_i > 0 || request.env[Grape::Http::Headers::HTTP_TRANSFER_ENCODING] == CHUNKED)

        return unless (input = env[Grape::Env::RACK_INPUT])

        input.rewind
        body = env[Grape::Env::API_REQUEST_INPUT] = input.read
        begin
          read_rack_input(body) if body && !body.empty?
        ensure
          input.rewind
        end
      end

      # store parsed input in env['api.request.body']
      def read_rack_input(body)
        fmt = request.media_type ? mime_types[request.media_type] : options[:default_format]

        unless content_type_for(fmt)
          throw :error, status: 415, message: "The provided content-type '#{request.media_type}' is not supported."
        end
        parser = Grape::Parser.parser_for fmt, **options
        if parser
          begin
            body = (env[Grape::Env::API_REQUEST_BODY] = parser.call(body, env))
            if body.is_a?(Hash)
              env[Grape::Env::RACK_REQUEST_FORM_HASH] = if env[Grape::Env::RACK_REQUEST_FORM_HASH]
                                                          env[Grape::Env::RACK_REQUEST_FORM_HASH].merge(body)
                                                        else
                                                          body
                                                        end
              env[Grape::Env::RACK_REQUEST_FORM_INPUT] = env[Grape::Env::RACK_INPUT]
            end
          rescue Grape::Exceptions::Base => e
            raise e
          rescue StandardError => e
            throw :error, status: 400, message: e.message, backtrace: e.backtrace, original_exception: e
          end
        else
          env[Grape::Env::API_REQUEST_BODY] = body
        end
      end

      def negotiate_content_type
        fmt = format_from_extension || format_from_params || options[:format] || format_from_header || options[:default_format]
        if content_type_for(fmt)
          env[Grape::Env::API_FORMAT] = fmt
        else
          throw :error, status: 406, message: "The requested format '#{fmt}' is not supported."
        end
      end

      def format_from_extension
        parts = request.path.split('.')

        if parts.size > 1
          extension = parts.last
          # avoid symbol memory leak on an unknown format
          return extension.to_sym if content_type_for(extension)
        end
        nil
      end

      def format_from_params
        fmt = Rack::Utils.parse_nested_query(env[Grape::Http::Headers::QUERY_STRING])[Grape::Http::Headers::FORMAT]
        # avoid symbol memory leak on an unknown format
        return fmt.to_sym if content_type_for(fmt)
        fmt
      end

      def format_from_header
        mime_array.each do |t|
          return mime_types[t] if mime_types.key?(t)
        end
        nil
      end

      def mime_array
        accept = env[Grape::Http::Headers::HTTP_ACCEPT]
        return [] unless accept

        accept_into_mime_and_quality = %r{
          (
            \w+/[\w+.-]+)     # eg application/vnd.example.myformat+xml
          (?:
           (?:;[^,]*?)?       # optionally multiple formats in a row
           ;\s*q=([\d.]+)     # optional "quality" preference (eg q=0.5)
          )?
        }x

        vendor_prefix_pattern = /vnd\.[^+]+\+/

        accept.scan(accept_into_mime_and_quality)
              .sort_by { |_, quality_preference| -quality_preference.to_f }
              .flat_map { |mime, _| [mime, mime.sub(vendor_prefix_pattern, '')] }
      end
    end
  end
end
