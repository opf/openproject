#-- encoding: UTF-8

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
    def call(params, work_packages: [])
      GithubPullRequest.find_or_initialize_by(github_id: params.fetch('id'))
                       .tap do |pr|
                         pr.update!(work_packages: pr.work_packages | work_packages, **extract_params(params))
                       end
    end

    private

    # Receives the input from the github webhook and translates them
    # to our internal representation.
    # See: https://docs.github.com/en/rest/reference/pulls
    # rubocop:disable Metrics/AbcSize
    def extract_params(params)
      {
        github_id: params.fetch('id'),
        github_user: github_user_id(params.fetch('user')),
        number: params.fetch('number'),
        github_html_url: params.fetch('html_url'),
        github_updated_at: params.fetch('updated_at'),
        state: params.fetch('state'),
        title: params.fetch('title'),
        body: params.fetch('body'),
        repository: params.fetch('base')
                          .fetch('repo')
                          .fetch('full_name'),
        draft: params.fetch('draft'),
        merged: params.fetch('merged'),
        merged_by: github_user_id(params['merged_by']),
        merged_at: params['merged_at'],
        comments_count: params.fetch('comments'),
        review_comments_count: params.fetch('review_comments'),
        additions_count: params.fetch('additions'),
        deletions_count: params.fetch('deletions'),
        changed_files_count: params.fetch('changed_files'),
        labels: params.fetch('labels').map { |values| extract_label_values(values) }
      }
    end
    # rubocop:enable Metrics/AbcSize

    def extract_label_values(params)
      {
        name: params.fetch('name'),
        color: params.fetch('color')
      }
    end

    def github_user_id(params)
      return if params.blank?

      ::OpenProject::GithubIntegration::Services::UpsertGithubUser.new.call(params)
    end
  end
end
