# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module Repositories
      module Pipelines
        class PipelineRepresenter < ::API::Decorators::Single
          include ::API::Decorators::DateProperty
          include ::API::V3::Repositories::AuthorProperty

          self_link path: :repository_pipeline,
                    title_getter: ->(*) { represented.status }

          link :mergeRequest do
            {
              href: api_v3_paths.repository_merge_request(represented.merge_request_id),
              title: represented.merge_request.title
            }
          end

          property :id
          property :status
          property :web_url
          property :details_url, render_nil: true
          author_property

          date_time_property :started_at
          date_time_property :completed_at
          date_time_property :created_at
          date_time_property :updated_at

          self.to_preload = %i[repository_user merge_request]

          def _type
            "RepositoryPipeline"
          end
        end
      end
    end
  end
end
