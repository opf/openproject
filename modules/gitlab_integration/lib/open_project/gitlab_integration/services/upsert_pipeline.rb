# frozen_string_literal: true

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
module OpenProject
  module GitlabIntegration
    module Services
      class UpsertPipeline
        include ParamsHelper

        def call(payload, merge_request:)
          GitlabPipeline.find_or_initialize_by(gitlab_id: payload.object_attributes.iid)
                        .tap do |pipeline|
                          pipeline.update!(gitlab_merge_request: merge_request, **extract_params(payload))
                        end
        end

        private

        # Receives the input from the gitlab webhook and translates them
        # to our internal representation.
        def extract_params(payload)
          {
            gitlab_id: payload.object_attributes.iid,
            gitlab_html_url: "#{payload.project.web_url}/-/pipelines/#{payload.object_attributes.iid}",
            project_id: payload.project.id,
            gitlab_user_avatar_url: avatar_url(payload.user.avatar_url),
            name: payload.object_attributes.iid,
            status: payload.object_attributes.status,
            details_url: "#{payload.project.web_url}/-/commit/#{payload.object_attributes.sha[0..7]}",
            commit_id: payload.object_attributes.sha[0..7],
            username: payload.user.name,
            ci_details: payload.builds,
            started_at: payload.object_attributes.created_at,
            completed_at: payload.object_attributes.finished_at
          }
        end
      end
    end
  end
end
