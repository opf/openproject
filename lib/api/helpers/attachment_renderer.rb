#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
      # @param external_link_expires_in [ActiveSupport::Duration] Time after which link expires. Default is 5 minutes.
      #                                                           Only applicable in case of external storage.
      def respond_with_attachment(attachment, external_link_expires_in: nil)
        if attachment.external_storage?
          redirect attachment.external_url(expires_in: external_link_expires_in).to_s
        else
          content_type attachment.content_type
          header['Content-Disposition'] = "#{attachment.content_disposition}; filename=#{attachment.filename}"
          env['api.format'] = :binary
          file attachment.diskfile
        end
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
