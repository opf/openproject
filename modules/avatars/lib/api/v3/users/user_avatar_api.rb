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

module API
  module V3
    module Users
      class UserAvatarAPI < ::API::OpenProjectAPI
        helpers ::AvatarHelper
        helpers ::API::Helpers::AttachmentRenderer

        finally do
          set_cache_headers
        end

        get "/avatar" do
          cache_seconds = @user == current_user ? nil : avatar_link_expires_in

          if (local_avatar = local_avatar?(@user))
            respond_with_attachment(local_avatar, cache_seconds:)
          elsif avatar_manager.gravatar_enabled?
            set_cache_headers!(cache_seconds) if cache_seconds

            redirect build_gravatar_image_url(@user)
          else
            status 404
          end
        rescue StandardError => e
          # Exceptions may happen due to invalid mails in the avatar builder
          # but we ensure that a 404 is returned in that case for consistency
          Rails.logger.error { "Failed to render #{@user&.id} avatar: #{e.message}" }
          status 404
        end
      end
    end
  end
end
