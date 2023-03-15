#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
    # Handles GitHub pull request notifications.
    class PullRequest
      include OpenProject::GithubIntegration::NotificationHandler::Helper
      include ActionView::Helpers::TagHelper
      include ::AngularHelper

      COMMENT_ACTIONS = %w[
        closed
        opened
        ready_for_review
        reopened
      ].freeze

      def process(params)
        @payload = wrap_payload(params)
        github_system_user = User.find_by(id: payload.open_project_user_id)
        work_packages = find_mentioned_work_packages(payload.pull_request.body, github_system_user)

        pull_request = upsert_pull_request(work_packages)

        comment_on_referenced_work_packages(
          work_packages_to_comment_on(payload.action, pull_request, work_packages),
          github_system_user,
          journal_entry(pull_request, payload)
        )
      end

      private

      attr_reader :payload

      def work_packages_to_comment_on(action, pull_request, work_packages)
        if action == 'edited'
          without_already_referenced(work_packages, pull_request)
        else
          COMMENT_ACTIONS.include?(action) ? work_packages : []
        end
      end

      def upsert_pull_request(work_packages)
        return if work_packages.empty? && pull_request.nil?

        OpenProject::GithubIntegration::Services::UpsertPullRequest.new.call(payload.pull_request.to_h,
                                                                             work_packages:)
      end

      def journal_entry(pull_request, payload)
        angular_component_tag 'macro',
                              class: 'github_pull_request',
                              inputs: {
                                pullRequestId: pull_request.id,
                                pullRequestState: pull_request_state(payload)
                              }
      end

      def pull_request_state(payload)
        key = {
          'opened' => 'opened',
          'reopened' => 'opened',
          'closed' => 'closed',
          'edited' => 'referenced',
          'referenced' => 'referenced',
          'ready_for_review' => 'ready_for_review'
        }[payload.action]

        return 'merged' if key == 'closed' && payload.pull_request.merged
        return 'draft' if key == 'open' && payload.pull_request.draft

        key
      end
    end
  end
end
