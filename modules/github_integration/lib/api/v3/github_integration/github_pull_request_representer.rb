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

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module GithubIntegration
      class GithubPullRequestRepresenter < ::API::Decorators::Single
        include API::Caching::CachedRepresenter
        include API::Decorators::DateProperty
        include API::Decorators::FormattableProperty
        include API::Decorators::LinkedResource

        cached_representer key_parts: %i[github_user merged_by],
                           disabled: false

        link :staticPath do
          next
        end

        property :id

        property :number

        property :github_html_url

        property :state,
                 render_nil: true

        property :repository,
                 render_nil: true

        date_time_property :github_updated_at,
                           render_nil: true,
                           setter: ->(*) { nil }

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

        property :github_user,
                 getter: ->(*) {
                   next unless github_user

                   {
                     login: github_user.github_login,
                     htmlUrl: github_user.github_html_url,
                     avatarUrl: github_user.github_avatar_url
                   }
                 }

        property :merged_by,
                 getter: ->(*) {
                   next unless merged_by

                   {
                     login: merged_by.github_login,
                     htmlUrl: merged_by.github_html_url,
                     avatarUrl: merged_by.github_avatar_url
                   }
                 },
                 render_nil: true

        property :github_check_runs,
                 getter: ->(*) {
                   latest_check_runs.map do |check_run|
                     {
                       htmlUrl: check_run.github_html_url,
                       appOwnerAvatarUrl: check_run.github_app_owner_avatar_url,
                       name: check_run.name,
                       status: check_run.status,
                       conclusion: check_run.conclusion,
                       outputTitle: check_run.output_title,
                       outputSummary: check_run.output_summary,
                       detailsUrl: check_run.details_url,
                       startedAt: check_run.started_at&.iso8601,
                       completedAt: check_run.completed_at&.iso8601
                     }
                   end
                 }

        date_time_property :created_at

        date_time_property :updated_at

        def _type
          'GithubPullRequest'
        end

        self.to_eager_load = %i[github_user
                                merged_by
                                github_check_runs]
      end
    end
  end
end
