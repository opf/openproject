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
module OpenProject::GithubIntegration::Services
  ##
  # Takes pull request data coming from GitHub webhook data and stores
  # them as a `GithubPullRequest`.
  # If the `GithubPullRequest` already exists, it is updated.
  #
  # Returns the upserted `GithubPullRequest`.
  #
  # See: https://docs.github.com/en/developers/webhooks-and-events/webhook-events-and-payloads#pull_request
  class UpsertPullRequest
    def call(payload, work_packages: [])
      find_or_initialize(payload).tap do |pr|
        pr.update!(work_packages: pr.work_packages | work_packages, **extract_params(payload))
      end
    end

    private

    def find_or_initialize(payload)
      GithubPullRequest.find_by_github_identifiers(id: payload.fetch("id"),
                                                   url: payload.fetch("html_url"),
                                                   initialize: true)
    end

    # Receives the input from the github webhook and translates them
    # to our internal representation.
    # See: https://docs.github.com/en/rest/reference/pulls
    # rubocop:disable Metrics/AbcSize
    def extract_params(payload)
      {
        github_id: payload.fetch("id"),
        github_user: github_user_id(payload.fetch("user")),
        number: payload.fetch("number"),
        github_html_url: payload.fetch("html_url"),
        github_updated_at: payload.fetch("updated_at"),
        state: payload.fetch("state"),
        title: payload.fetch("title"),
        body: payload.fetch("body"),
        repository: payload.fetch("base")
                          .fetch("repo")
                          .fetch("full_name"),
        repository_html_url: payload.fetch("base")
                                    .fetch("repo")
                                    .fetch("html_url"),
        draft: payload.fetch("draft"),
        merge_commit_sha: payload["merge_commit_sha"],
        merged: payload.fetch("merged"),
        merged_by: github_user_id(payload["merged_by"]),
        merged_at: payload["merged_at"],
        comments_count: payload.fetch("comments"),
        review_comments_count: payload.fetch("review_comments"),
        additions_count: payload.fetch("additions"),
        deletions_count: payload.fetch("deletions"),
        changed_files_count: payload.fetch("changed_files"),
        labels: payload.fetch("labels").map { |values| extract_label_values(values) }
      }
    end
    # rubocop:enable Metrics/AbcSize

    def extract_label_values(payload)
      {
        name: payload.fetch("name"),
        color: payload.fetch("color")
      }
    end

    def github_user_id(payload)
      return if payload.blank?

      ::OpenProject::GithubIntegration::Services::UpsertGithubUser.new.call(payload)
    end
  end
end
