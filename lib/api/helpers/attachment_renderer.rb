#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

##
# Attachment helper to be included into endpoints
module API
  module Helpers
    module AttachmentRenderer
      def self.content_endpoint(&block)
        ->(*) {
          helpers ::API::Helpers::AttachmentRenderer

          finally do
            set_cache_headers
          end

          get do
            attachment = instance_exec(&block)
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
        prepare_cache_headers(cache_seconds) if cache_seconds

        if attachment.external_storage?
          redirect_to_external_attachment(attachment, cache_seconds)
        else
          send_attachment(attachment)
        end
      end

      private

      def redirect_to_external_attachment(attachment, cache_seconds)
        set_cache_headers!
        redirect attachment.external_url(expires_in: cache_seconds).to_s
      end

      def send_attachment(attachment)
        content_type attachment.content_type
        header['Content-Disposition'] = "#{attachment.content_disposition}; filename=#{attachment.filename}"
        env['api.format'] = :binary
        sendfile attachment.diskfile.path
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
