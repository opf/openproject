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
      class CreateCommit
        include ParamsHelper

        def call(payload, event_payload, work_packages: [])
          GitlabCommit.find_or_create_by!(sha: payload.id) do |commit|
            assign_commit_attributes(commit, payload)
            assign_event_attributes(commit, event_payload)
            commit.work_packages = work_packages
          end
        end

        private

        def find_or_initialize(payload)
          GitlabMergeRequest.find_by_gitlab_identifiers(id: payload.object_attributes.iid,
                                                        url: payload.object_attributes.url,
                                                        initialize: true)
        end

        def assign_commit_attributes(commit, payload)
          commit.message = payload.message || ""
          commit.author_name = payload.author.name
          commit.author_email = payload.author.email
          commit.authored_at = payload.timestamp
          commit.gitlab_html_url = payload.url
        end

        def assign_event_attributes(commit, payload)
          commit.gitlab_user_id = gitlab_user(payload)
          commit.repository = payload.repository.name
        end

        def gitlab_user(payload)
          user = ::OpenProject::GitlabIntegration::NotificationHandler::Helper::Payload.new(
            {
              "id" => payload.user_id,
              "name" => payload.user_name,
              "username" => payload.user_username,
              "email" => payload.user_email,
              "avatar_url" => payload.user_avatar
            }
          )
          ::OpenProject::GitlabIntegration::Services::UpsertGitlabUser.new.call(user)
        end
      end
    end
  end
end
