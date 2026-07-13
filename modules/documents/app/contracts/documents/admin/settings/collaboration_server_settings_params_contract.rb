# frozen_string_literal: true

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

module Documents
  module Admin
    module Settings
      class CollaborationServerSettingsParamsContract < ::ParamsContract
        include RequiresAdminGuard

        validate :validate_collaborative_editing_hocuspocus_url

        # Expose the param value as a method so that ActiveModel::Errors#full_messages
        # can resolve the attribute without hitting Disposable::Twin's method_missing.
        def collaborative_editing_hocuspocus_url
          params[:collaborative_editing_hocuspocus_url]
        end

        private

        def validate_collaborative_editing_hocuspocus_url
          url = params[:collaborative_editing_hocuspocus_url]
          return if url.blank?
          return if websocket_url?(url)

          errors.add :collaborative_editing_hocuspocus_url, :invalid,
                     message: I18n.t("documents.admin.collaboration_settings.hocuspocus_server_url.invalid_scheme")
        end

        def websocket_url?(url)
          uri = URI.parse(url)
          uri.is_a?(URI::WS) || uri.is_a?(URI::WSS)
        rescue URI::InvalidURIError
          false
        end
      end
    end
  end
end
