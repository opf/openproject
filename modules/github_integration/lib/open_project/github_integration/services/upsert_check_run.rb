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
  # Takes check_run data coming from GitHub webhook data and stores
  # them as a `GithubCheckRun`.
  # If the `GithubCheckRun` already exists, it is updated.
  #
  # Returns the upserted `GithubCheckRun`.
  #
  # See: https://docs.github.com/en/developers/webhooks-and-events/webhook-events-and-payloads#check_run
  class UpsertCheckRun
    def call(payload, pull_request:)
      GithubCheckRun.find_or_initialize_by(github_id: payload.fetch("id"))
                    .tap do |check_run|
                      check_run.update!(github_pull_request: pull_request, **extract_params(payload))
                    end
    end

    private

    # Receives the input from the github webhook and translates them
    # to our internal representation.
    # See: https://docs.github.com/en/rest/reference/checks
    def extract_params(payload)
      output = payload.fetch("output")
      app = payload.fetch("app")

      {
        github_id: payload.fetch("id"),
        github_html_url: payload.fetch("html_url"),
        app_id: app.fetch("id"),
        github_app_owner_avatar_url: app.fetch("owner")
                                        .fetch("avatar_url"),
        name: payload.fetch("name"),
        status: payload.fetch("status"),
        conclusion: payload["conclusion"],
        output_title: output.fetch("title"),
        output_summary: output.fetch("summary"),
        details_url: payload["details_url"],
        started_at: payload["started_at"],
        completed_at: payload["completed_at"]
      }
    end
  end
end
