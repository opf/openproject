# frozen_string_literal: true

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
module OpenProject
  module GitlabIntegration
    module Services
      ##
      # Takes user data coming from Gitlab webhook data and stores
      # them as a `GitlabUser`.
      # If the `GitlabUser` already exists, it is updated.
      #
      # Returns the upserted `GitlabUser`.
      class UpsertGitlabUser
        def call(payload)
          GitlabUser.find_or_initialize_by(gitlab_id: payload.id)
                    .tap do |gitlab_user|
                      gitlab_user.update!(extract_params(payload))
                    end
        end

        private

        ##
        # Receives the input from the gitlab webhook and translates them
        # to our internal representation.
        def extract_params(payload)
          {
            gitlab_id: payload.id,
            gitlab_name: payload.name,
            gitlab_username: payload.username,
            gitlab_email: payload.email,
            gitlab_avatar_url: avatar_url(payload)
          }
        end

        def avatar_url(payload)
          # rubocop:disable Layout/LineLength
          payload.avatar_url.presence || "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='24' height='24'%3E%3Cpath d='M12 2.5a5.5 5.5 0 0 1 3.096 10.047 9.005 9.005 0 0 1 5.9 8.181.75.75 0 1 1-1.499.044 7.5 7.5 0 0 0-14.993 0 .75.75 0 0 1-1.5-.045 9.005 9.005 0 0 1 5.9-8.18A5.5 5.5 0 0 1 12 2.5ZM8 8a4 4 0 1 0 8 0 4 4 0 0 0-8 0Z'%3E%3C/path%3E%3C/svg%3E"
          # rubocop:enable Layout/LineLength
        end
      end
    end
  end
end
