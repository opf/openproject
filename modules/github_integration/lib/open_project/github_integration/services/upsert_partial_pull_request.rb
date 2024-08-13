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
  # issue_comments webhooks don't give us the full PR data, but just a a subset, e.g. html_url, state and title
  # As described in [the docs](https://docs.github.com/en/rest/reference/issues#list-organization-issues-assigned-to-the-authenticated-user),
  # pull request are considered to also be issues.
  #
  # Returns the upserted partial `GithubPullRequest`.
  class UpsertPartialPullRequest
    def call(payload, work_packages:)
      params = extract_params(payload)

      find_or_initialize(params[:github_html_url]).tap do |pr|
        pr.update!(work_packages: pr.work_packages | work_packages, **extract_params(payload))
      end
    end

    private

    def extract_params(payload)
      {
        github_html_url: payload.issue.pull_request.html_url,
        github_updated_at: payload.issue.updated_at,
        github_user: github_user_id(payload.issue.user.to_h),
        number: payload.issue.number,
        state: payload.issue.state,
        repository: payload.repository.full_name,
        title: payload.issue.title
      }
    end

    def find_or_initialize(github_html_url)
      GithubPullRequest.find_or_initialize_by(github_html_url:)
    end

    def github_user_id(payload)
      return if payload.blank?

      ::OpenProject::GithubIntegration::Services::UpsertGithubUser.new.call(payload)
    end
  end
end
