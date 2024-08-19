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

require "roar/decorator"
require "roar/json/hal"

module API
  module V3
    module GithubPullRequests
      class GithubPullRequestRepresenter < ::API::Decorators::Single
        include API::Caching::CachedRepresenter
        include API::Decorators::DateProperty
        include API::Decorators::FormattableProperty
        include API::Decorators::LinkedResource

        def initialize(model, current_user:, **_opts)
          # We force `embed_links` so that github_user and github_check_runs
          # are embedded and we can avoid having separate endpoints.
          super(model, current_user:, embed_links: true)
        end

        cached_representer key_parts: %i[github_user merged_by]

        property :id

        property :number

        property :github_html_url, as: :htmlUrl

        property :state,
                 render_nil: true

        property :repository

        property :repository_html_url

        date_time_property :github_updated_at,
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

        property :merged_at,
                 render_nil: true

        property :comments_count,
                 render_nil: true

        property :review_comments_count,
                 render_nil: true

        property :additions_count,
                 render_nil: true

        property :deletions_count,
                 render_nil: true

        property :changed_files_count,
                 render_nil: true

        property :labels

        associated_resource :github_user,
                            representer: ::API::V3::GithubPullRequests::GithubUserRepresenter,
                            link_title_attribute: :github_login

        associated_resource :merged_by,
                            representer: ::API::V3::GithubPullRequests::GithubUserRepresenter,
                            v3_path: :github_user,
                            link_title_attribute: :github_login

        associated_resources :latest_check_runs,
                             as: :checkRuns,
                             representer: ::API::V3::GithubPullRequests::GithubCheckRunRepresenter,
                             v3_path: :github_check_run,
                             link_title_attribute: :name

        date_time_property :created_at

        date_time_property :updated_at

        def _type
          "GithubPullRequest"
        end

        self.to_eager_load = %i[github_user merged_by]
      end
    end
  end
end
