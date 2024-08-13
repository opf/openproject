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

require "roar/decorator"
require "roar/json/hal"

module API
  module V3
    module GitlabMergeRequests
      class GitlabMergeRequestRepresenter < ::API::Decorators::Single
        include API::Caching::CachedRepresenter
        include API::Decorators::DateProperty
        include API::Decorators::FormattableProperty
        include API::Decorators::LinkedResource

        def initialize(model, current_user:, **_opts)
          # We force `embed_links` so that github_user and github_check_runs
          # are embedded and we can avoid having separate endpoints.
          super(model, current_user:, embed_links: true)
        end

        cached_representer key_parts: %i[gitlab_user merged_by]

        property :id

        property :number

        property :gitlab_html_url, as: :htmlUrl

        property :state,
                 render_nil: true

        property :repository,
                 render_nil: true

        date_time_property :gitlab_updated_at,
                           render_nil: true,
                           setter: ->(*) {}

        property :title,
                 render_nil: true

        formattable_property :body,
                             render_nil: true

        property :draft,
                 render_nil: true

        property :merged,
                 render_nil: true

        property :labels

        associated_resource :gitlab_user,
                            representer: ::API::V3::GitlabMergeRequests::GitlabUserRepresenter,
                            link_title_attribute: :gitlab_name

        associated_resource :merged_by,
                            representer: ::API::V3::GitlabMergeRequests::GitlabUserRepresenter,
                            v3_path: :gitlab_user,
                            link_title_attribute: :gitlab_name

        # TODO: pending until get the list of statuses...
        associated_resources :latest_pipelines,
                             as: :pipelines,
                             representer: ::API::V3::GitlabMergeRequests::GitlabPipelineRepresenter,
                             v3_path: :gitlab_pipeline,
                             link_title_attribute: :name

        date_time_property :created_at

        date_time_property :updated_at

        def _type
          "GitlabMergeRequest"
        end

        self.to_eager_load = %i[gitlab_user merged_by]
      end
    end
  end
end
