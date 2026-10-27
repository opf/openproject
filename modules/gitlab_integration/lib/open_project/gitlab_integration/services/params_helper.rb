# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 Ben Tey
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
# Copyright (C) the OpenProject GmbH
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
module OpenProject
  module GitlabIntegration
    module Services
      module ParamsHelper
        private

        EMPTY_AVATAR_URL = "https://www.gravatar.com/avatar/?d=mp"

        def avatar_url(raw_url)
          raw_url.presence || EMPTY_AVATAR_URL
        end

        def repository_user(user_payload, provider)
          return if user_payload.blank?

          UpsertRepositoryUser.new.call(user_payload, provider:)
        end

        # Push hooks flatten the pusher into user_* keys instead of the nested
        # "user" object every other GitLab event sends.
        def pusher(push_payload, provider)
          user_payload = ::OpenProject::GitlabIntegration::NotificationHandler::Helper::Payload.new(
            "id" => push_payload.user_id,
            "name" => push_payload.user_name,
            "username" => push_payload.user_username,
            "avatar_url" => push_payload.user_avatar
          )
          repository_user(user_payload, provider)
        end

        def labels(label_payloads)
          label_payloads.map { |label| { title: label["title"], color: label["color"] } }
        end
      end
    end
  end
end
