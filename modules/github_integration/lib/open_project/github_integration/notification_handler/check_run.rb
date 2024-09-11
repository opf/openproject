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

module OpenProject::GithubIntegration
  module NotificationHandler
    ##
    # Handles GitHub issue comment notifications.
    class CheckRun
      include OpenProject::GithubIntegration::NotificationHandler::Helper

      def process(params)
        @payload = wrap_payload(params)
        return unless associated_with_pr?

        pull_request = find_pull_request
        return unless pull_request

        OpenProject::GithubIntegration::Services::UpsertCheckRun.new.call(
          payload.check_run.to_h,
          pull_request:
        )
      end

      private

      attr_reader :payload

      def associated_with_pr?
        payload.check_run.pull_requests?.present?
      end

      def find_pull_request
        github_id = payload.check_run
                           .pull_requests
                           .first
                           .fetch("id")
        GithubPullRequest.find_by(github_id:)
      end
    end
  end
end
