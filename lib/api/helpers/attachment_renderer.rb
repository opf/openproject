#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

##
# Attachment helper to be included into endpoints
module API
  module Helpers
    module AttachmentRenderer
      def self.content_endpoint(&)
        ->(*) {
          helpers ::API::Helpers::AttachmentRenderer

          finally do
            set_cache_headers
          end

          get do
            attachment = instance_exec(&)
            respond_with_attachment attachment, cache_seconds: fog_cache_seconds
          end
        }
      end

      ##
      # Render an attachment, either by redirecting
      # to the external storage,
      #
      # or by directly rendering the file
      #
      # @param attachment [Attachment] Attachment to be responded with.
      # @param cache_seconds [integer] Time in seconds the cache headers signal the browser to cache the attachment.
      #                                Defaults to no cache headers.
      def respond_with_attachment(attachment, cache_seconds: nil)
        validate_attachment_access!(attachment)
        prepare_cache_headers(cache_seconds) if cache_seconds

        if attachment.external_storage?
          redirect_to_external_attachment(attachment, cache_seconds)
        else
          send_attachment(attachment)
        end
      end

      private

      def validate_attachment_access!(attachment)
        if attachment.status_quarantined?
          raise ::API::Errors::Unauthorized.new(message: I18n.t("antivirus_scan.quarantined_message",
                                                                filename: attachment.filename))
        end

        if attachment.author != current_user && attachment.pending_virus_scan?
          raise ::API::Errors::Unauthorized.new(message: I18n.t("antivirus_scan.not_processed_yet_message",
                                                                filename: attachment.filename))
        end
      end

      def redirect_to_external_attachment(attachment, cache_seconds)
        set_cache_headers!
        redirect attachment.external_url(expires_in: cache_seconds).to_s
      end

      def send_attachment(attachment)
        if attachment.diskfile.nil?
          raise ::API::Errors::NotFound.new
        end

        content_type attachment_content_type(attachment)
        header["Content-Disposition"] = attachment.content_disposition
        env["api.format"] = :binary
        sendfile attachment.diskfile.path
      end

      def attachment_content_type(attachment)
        if attachment.is_text?
          # Even if the text mime type might differ, always output plain text
          # so this doesn't get interpreted as e.g., a script or html file
          "text/plain"
        elsif attachment.inlineable?
          attachment.content_type
        else
          # For security reasons, mark all non-inlinable files as an octet-stream first
          "application/octet-stream"
        end
      end

      def set_cache_headers
        set_cache_headers! if @stream
      end

      def prepare_cache_headers(seconds)
        @prepared_cache_headers = { "Cache-Control" => "public, max-age=#{seconds}",
                                    "Expires" => CGI.rfc1123_date(Time.now.utc + seconds) }
      end

      def set_cache_headers!(seconds = nil)
        prepare_cache_headers(seconds) if seconds

        (@prepared_cache_headers || {}).each do |key, value|
          header key, value
        end
      end

      def fog_cache_seconds
        [
          0,
          OpenProject::Configuration.fog_download_url_expires_in.to_i - 10
        ].max
      end

      def avatar_link_expires_in
        seconds = avatar_link_expiry_seconds

        if seconds == 0
          nil
        else
          seconds.seconds
        end
      end

      def avatar_link_expiry_seconds
        @avatar_link_expiry_seconds ||= OpenProject::Configuration.avatar_link_expiry_seconds.to_i
      end
    end
  end
end
