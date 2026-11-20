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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module Users
      class UserAvatarAPI < ::API::OpenProjectAPI
        helpers ::AvatarHelper
        helpers ::API::Helpers::AttachmentRenderer

        helpers do
          def render_initials_svg(cache_seconds)
            set_cache_headers!(cache_seconds) if cache_seconds

            content_type "image/svg+xml"
            env["api.format"] = :binary
            body ::OpenProject::Avatars::InitialsSvg.render(@user)
          end

          def render_uploaded_image
            raise ::API::Errors::NotFound unless @user == current_user || current_user.admin?

            respond_with_attachment(local_avatar?(@user) || raise(::API::Errors::NotFound))
          end
        end

        finally do
          set_cache_headers
        end

        get "/avatar" do
          cache_seconds = @user == current_user ? nil : avatar_link_expires_in
          avatar_type = avatar_manager.avatar_type_for(@user)

          # Requested by the frontend's <img onerror> handler after a local avatar
          # or Gravatar request failed (e.g. no Gravatar registered for the user's
          # email). Rendering the generated avatar directly, without attempting
          # local/Gravatar again, avoids a server-side round trip to Gravatar and
          # the redirect loop that would otherwise occur.
          if params[:source] == "image"
            render_uploaded_image
          elsif params[:fallback].blank? && avatar_type == "image" && (local_avatar = local_avatar?(@user))
            respond_with_attachment(local_avatar, cache_seconds:)
          elsif params[:fallback].blank? && avatar_type == "gravatar"
            set_cache_headers!(cache_seconds) if cache_seconds

            redirect build_gravatar_image_url(@user)
          else
            render_initials_svg(cache_seconds)
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
