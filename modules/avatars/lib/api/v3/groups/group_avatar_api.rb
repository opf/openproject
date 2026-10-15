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

module API
  module V3
    module Groups
      class GroupAvatarAPI < ::API::OpenProjectAPI
        helpers ::AvatarHelper
        helpers ::API::Helpers::AttachmentRenderer
        helpers ::API::Caching::Helpers

        # Groups have no email address, so there is no Gravatar fallback here,
        # unlike the equivalent user endpoint.
        #
        # Unlike a user's own avatar, there is no "it's me, don't cache"
        # exception here (see UserAvatarAPI's cache_seconds = nil check) --
        # whoever just changed a group's avatar is always someone else from
        # the browser cache's perspective, on every page that shows it. A
        # long-lived Cache-Control would mean that change stays invisible
        # everywhere for up to a day. ETag + must-revalidate keeps the browser
        # cache (a cheap 304 when nothing changed) while guaranteeing every
        # view reflects the current avatar on the next load.
        get "/avatar" do
          header "Cache-Control", "public, max-age=0, must-revalidate"
          with_etag! [@group.id, @group.detail&.updated_at, @group.local_avatar_attachment&.updated_at]

          if avatar_manager.avatar_type_for(@group) == "image" && (local_avatar = local_avatar?(@group))
            respond_with_attachment(local_avatar)
          else
            content_type "image/svg+xml"
            env["api.format"] = :binary
            body ::OpenProject::Avatars::InitialsSvg.render(@group)
          end
        rescue StandardError => e
          Rails.logger.error { "Failed to render #{@group&.id} avatar: #{e.message}" }
          status 404
        end
      end
    end
  end
end
