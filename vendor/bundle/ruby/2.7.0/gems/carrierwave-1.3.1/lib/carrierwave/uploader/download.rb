require 'open-uri'

module CarrierWave
  module Uploader
    module Download
      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Callbacks
      include CarrierWave::Uploader::Configuration
      include CarrierWave::Uploader::Cache

      class RemoteFile
        def initialize(uri, remote_headers = {})
          @uri = uri
          @remote_headers = remote_headers
          @file = nil
        end

        def original_filename
          filename = filename_from_header || filename_from_uri
          mime_type = MIME::Types[file.content_type].first
          unless File.extname(filename).present? || mime_type.blank?
            filename = "#{filename}.#{mime_type.extensions.first}"
          end
          filename
        end

        def respond_to?(*args)
          super or file.respond_to?(*args)
        end

        def http?
          @uri.scheme =~ /^https?$/
        end

      private

        def file
          if @file.blank?
            headers = @remote_headers.
              reverse_merge('User-Agent' => "CarrierWave/#{CarrierWave::VERSION}")

            @file = Kernel.open(@uri.to_s, headers)
            @file = @file.is_a?(String) ? StringIO.new(@file) : @file
          end
          @file

        rescue StandardError => e
          raise CarrierWave::DownloadError, "could not download file: #{e.message}"
        end

        def filename_from_header
          if file.meta.include? 'content-disposition'
            match = file.meta['content-disposition'].match(/filename="?([^"]+)/)
            return match[1] unless match.nil? || match[1].empty?
          end
        end

        def filename_from_uri
          URI.decode(File.basename(file.base_uri.path))
        end

        def method_missing(*args, &block)
          file.send(*args, &block)
        end
      end

      ##
      # Caches the file by downloading it from the given URL.
      #
      # === Parameters
      #
      # [url (String)] The URL where the remote file is stored
      # [remote_headers (Hash)] Request headers
      #
      def download!(uri, remote_headers = {})
        processed_uri = process_uri(uri)
        file = RemoteFile.new(processed_uri, remote_headers)
        raise CarrierWave::DownloadError, "trying to download a file which is not served over HTTP" unless file.http?
        cache!(file)
      end

      ##
      # Processes the given URL by parsing and escaping it. Public to allow overriding.
      #
      # === Parameters
      #
      # [url (String)] The URL where the remote file is stored
      #
      def process_uri(uri)
        URI.parse(uri)
      rescue URI::InvalidURIError
        uri_parts = uri.split('?')
        # regexp from Ruby's URI::Parser#regexp[:UNSAFE], with [] specifically removed
        encoded_uri = URI.encode(uri_parts.shift, /[^\-_.!~*'()a-zA-Z\d;\/?:@&=+$,]/)
        encoded_uri << '?' << URI.encode(uri_parts.join('?')) if uri_parts.any?
        URI.parse(encoded_uri) rescue raise CarrierWave::DownloadError, "couldn't parse URL"
      end

    end # Download
  end # Uploader
end # CarrierWave
