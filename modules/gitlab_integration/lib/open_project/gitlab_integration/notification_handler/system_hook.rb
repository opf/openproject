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

module OpenProject::GitlabIntegration
  module NotificationHandler
    ##
    # Handles Gitlab commit notifications.
    class SystemHook
      include OpenProject::GitlabIntegration::NotificationHandler::Helper

      def process(payload_params) # rubocop:disable Metrics/AbcSize
        @payload = wrap_payload(payload_params)
        return nil unless payload.object_kind == "push"

        payload.commits.each do |commit|
          user = User.find_by_id(payload.open_project_user_id)
          text = [commit["title"], commit["message"]]
            .select(&:present?)
            .join(" - ")
          work_packages = find_mentioned_work_packages(text, user)
          notes = generate_notes(commit, payload)
          comment_on_referenced_work_packages(work_packages, user, notes)
        end
      end

      private

      attr_reader :payload

      def generate_notes(commit, payload)
        commit_id = commit["id"]
        I18n.t("gitlab_integration.push_single_commit_comment",
               commit_number: commit_id[0, 8],
               commit_note: commit["message"].presence || commit["title"],
               commit_url: commit["url"],
               commit_timestamp: commit["timestamp"],
               repository: payload.repository.name,
               repository_url: payload.repository.homepage,
               gitlab_user: payload.user_name,
               gitlab_user_url: payload.user_avatar)
      end
    end
  end
end
