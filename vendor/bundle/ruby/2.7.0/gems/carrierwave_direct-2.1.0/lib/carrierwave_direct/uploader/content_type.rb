module CarrierWaveDirect
  module Uploader
    module ContentType

      def content_type
        default_content_type ? default_content_type : 'binary/octet-stream'
      end

      def content_types
        types = allowed_content_types

        return types if types.is_a? Array

        %w(application/atom+xml application/ecmascript application/json
          application/javascript application/octet-stream application/ogg
          application/pdf application/postscript application/rss+xml
          application/font-woff application/xhtml+xml application/xml
          application/xml-dtd application/zip application/gzip audio/basic
          audio/mp4 audio/mpeg audio/ogg audio/vorbis audio/vnd.rn-realaudio
          audio/vnd.wave audio/webm image/gif image/jpeg image/pjpeg
          image/png image/svg+xml image/tiff text/cmd text/css text/csv
          text/html text/javascript text/plain text/vcard text/xml video/mpeg
          video/mp4 video/ogg video/quicktime video/webm video/x-matroska
          video/x-ms-wmv video/x-flv)
      end
    end
  end
end
