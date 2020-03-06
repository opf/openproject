#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
        if cache_seconds
          set_cache_headers!(cache_seconds)
        end

        if attachment.external_storage?
          redirect attachment.external_url(expires_in: cache_seconds).to_s
        else
          content_type attachment.content_type
          header['Content-Disposition'] = "#{attachment.content_disposition}; filename=#{attachment.filename}"
          env['api.format'] = :binary
          file attachment.diskfile.path
        end
      end

      def set_cache_headers!(seconds)
        header "Cache-Control", "public, max-age=#{seconds}"
        header "Expires", CGI.rfc1123_date(Time.now.utc + seconds)
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
