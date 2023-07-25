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
# See COPYRIGHT and LICENSE files for more details.
#++
module OpenProject::GitlabIntegration::Services
  ##
  # Takes pipelines CI data coming from Gitlab webhook data and stores
  # them as a `GitlabPipeline`.
  # If the `GitlabPipeline` already exists, it is updated.
  #
  # Returns the upserted `GitlabPipeline`.
  class UpsertPipeline
    def call(payload, merge_request:)
      GitlabPipelines.find_or_initialize_by(gitlab_id: payload.object_attributes.id)
                    .tap do |pipeline|
                      pipeline.update!(gitlab_merge_request: merge_request, **extract_params(payload))
                    end
    end

    private

    # Receives the input from the gitlab webhook and translates them
    # to our internal representation.
    def extract_params(payload)
      {
        gitlab_id: payload.object_attributes.id,
        gitlab_html_url: payload.project.web_url + "-/pipelines/" + payload.object_attributes.id,
        project_id: payload.project.id,
        gitlab_user_avatar_url: payload.user.avatar_url,
        name: payload.object_attributes.status,
        status: payload.object_attributes.status,
        details_url: payload.project.web_url + "-/pipelines/" + payload.object_attributes.id,
        # ci_details: pending until resolution of the gitlab issue,
        started_at: payload.object_attributes.created_at,
        completed_at: payload.object_attributes.finished_at
      }
    end
  end
end