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
    class IssueComment
      include OpenProject::GithubIntegration::NotificationHandler::Helper
      include ActionView::Helpers::TagHelper
      include ::AngularHelper

      COMMENT_ACTIONS = %w[
        created
        edited
      ].freeze

      def process(params)
        @payload = wrap_payload(params)
        return unless associated_with_pr?

        github_system_user = User.find_by(id: payload.open_project_user_id)
        work_packages = find_mentioned_work_packages(payload.comment.body, github_system_user)

        new_work_packages = without_already_referenced(work_packages, pull_request&.work_packages.to_a || [])
        return if new_work_packages.none?

        pull_request = upsert_partial_pull_request(new_work_packages)
        notes = journal_entry(pull_request, payload)

        comment_on_referenced_work_packages(new_work_packages, github_system_user, notes)
      end

      private

      attr_reader :payload

      def associated_with_pr?
        payload.issue.pull_request?.present?
      end

      def pull_request
        @pull_request ||= GithubPullRequest.find_by(github_html_url: payload.issue.pull_request.html_url)
      end

      def upsert_partial_pull_request(work_packages)
        # Sadly, the webhook data for `issue_comment` events does not give us proper PR data (nor githubs PR id).
        # Thus, we have to search for the only data we have: html_url.
        # Even worse, when the PR is unknown to us, we don't have any useful data to create a GithubPullRequest record.
        # We still want to create a PR record (even if it just has partial data), to remember that it was referenced
        # and avoid adding reference-comments twice.
        OpenProject::GithubIntegration::Services::UpsertPartialPullRequest.new.call(
          payload,
          work_packages:
        )
      end

      def journal_entry(pull_request, payload)
        return unless COMMENT_ACTIONS.include?(payload.action)

        angular_component_tag "macro",
                              class: "github_pull_request",
                              inputs: {
                                pullRequestId: pull_request.id,
                                pullRequestState: "referenced"
                              }
      end
    end
  end
end
