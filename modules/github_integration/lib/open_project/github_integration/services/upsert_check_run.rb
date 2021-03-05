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
  # Takes user data coming from GitHub webhook data and stores
  # them as a `GithubUser`.
  # If the `GithubUser` already exists, it is updated.
  #
  # Returns the upserted `GithubCheckRun`.
  #
  # See: https://docs.github.com/en/developers/webhooks-and-events/webhook-events-and-payloads#check_run
  class UpsertCheckRun
    def call(params, pull_request:)
      params = extract_params(params)
      GithubCheckRun.find_or_initialize_by(github_html_url: params.fetch(:github_id))
                    .tap { |pr| pr.update!(github_pull_request: pull_request, **params) }
    end

    private

    # Receives the input from the github webhook and translates them
    # to our internal representation.
    # See: https://docs.github.com/en/rest/reference/checks
    def extract_params(params)
      output = params.fetch('output')

      {
        github_id: params.fetch('id'),
        github_html_url: params.fetch('html_url'),
        github_app_owner_avatar_url: params.fetch('app')
                                           .fetch('owner')
                                           .fetch('avatar_url'),
        status: params.fetch('status'),
        conclusion: params['conclusion'],
        output_title: output.fetch('title'),
        output_summary: output.fetch('summary'),
        details_url: params['details_url'],
        started_at: params['started_at'],
        completed_at: params['completed_at']
      }
    end
  end
end
