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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require Rails.root.join("db/migrate/migration_utils/utils")

class FillFromGitlab < ActiveRecord::Migration[8.1]
  include Migration::Utils

  # rubocop:disable-next Metrics/AbcSize, Layout/LineLength
  def up
    mr_url = execute("SELECT gitlab_html_url FROM gitlab_merge_requests WHERE gitlab_html_url != '' ORDER BY id DESC LIMIT 1").first&.fetch("gitlab_html_url")
    issue_url = execute("SELECT gitlab_html_url FROM gitlab_issues WHERE gitlab_html_url != '' ORDER BY id DESC LIMIT 1").first&.fetch("gitlab_html_url")
    return if mr_url.blank? && issue_url.blank?

    base_url = URI.parse(mr_url.presence || issue_url).tap { |u| u.path = "" }
    options = Setting.plugin_openproject_gitlab_integration.merge(url: base_url)
    ActiveRecord::Base.transaction do
      execute(<<~SQL.squish)
        INSERT INTO repository_providers (name, type, options, created_at, updated_at)
        VALUES('GitLab', 'Repositories::GitlabProvider', '#{options.to_json}', NOW(), NOW())
      SQL

      provider_id = execute("SELECT id FROM repository_providers WHERE type = 'Repositories::GitlabProvider' LIMIT 1").first&.fetch("id")

      execute(<<~SQL.squish)
        INSERT INTO repository_users(provider_id, external_id, name, username, avatar_url, created_at, updated_at)
        SELECT #{provider_id}, gitlab_id, name, username, avatar_url, created_at, updated_at FROM gitlab_users
        WHERE created_at IS NOT NULL AND updated_at IS NOT NULL
      SQL

      execute(<<~SQL.squish)
        INSERT INTO repository_issues(
          provider_id,
          repository_user_id,
          external_id,
          number,
          web_url,
          state,
          project_name,
          title,
          body,
          labels,
          external_updated_at,
          created_at,
          updated_at
        )
        SELECT
          #{provider_id},
          repository_users.id,
          gitlab_issues.gitlab_id,
          gitlab_issues.number,
          gitlab_issues.gitlab_html_url,
          gitlab_issues.state,
          gitlab_issues.repository,
          gitlab_issues.title,
          gitlab_issues.body,
          gitlab_issues.labels,
          gitlab_issues.gitlab_updated_at,
          gitlab_issues.created_at,
          gitlab_issues.updated_at
        FROM gitlab_issues
        LEFT OUTER JOIN gitlab_users ON gitlab_users.id = gitlab_issues.gitlab_user_id
        LEFT OUTER JOIN repository_users ON repository_users.external_id = gitlab_users.gitlab_id::varchar
                                         AND repository_users.provider_id = #{provider_id}
        WHERE gitlab_issues.title IS NOT NULL AND gitlab_issues.body IS NOT NULL AND
              gitlab_issues.created_at IS NOT NULL AND gitlab_issues.updated_at IS NOT NULL
      SQL

      execute(<<~SQL.squish)
        INSERT INTO repository_merge_requests(
          provider_id,
          repository_user_id,
          merged_by_id,
          external_id,
          number,
          web_url,
          state,
          project_name,
          title,
          body,
          labels,
          external_updated_at,
          created_at,
          updated_at
        )
        SELECT
          #{provider_id},
          repository_users.id,
          repo_mergers.id,
          gitlab_merge_requests.gitlab_id,
          gitlab_merge_requests.number,
          gitlab_merge_requests.gitlab_html_url,
          gitlab_merge_requests.state,
          gitlab_merge_requests.repository,
          gitlab_merge_requests.title,
          gitlab_merge_requests.body,
          gitlab_merge_requests.labels,
          gitlab_merge_requests.gitlab_updated_at,
          gitlab_merge_requests.created_at,
          gitlab_merge_requests.updated_at
        FROM gitlab_merge_requests
        LEFT OUTER JOIN gitlab_users ON gitlab_users.id = gitlab_merge_requests.gitlab_user_id
        LEFT OUTER JOIN repository_users ON repository_users.external_id = gitlab_users.gitlab_id::varchar
                                         AND repository_users.provider_id = #{provider_id}
        LEFT OUTER JOIN gitlab_users AS gl_mergers ON gl_mergers.id = gitlab_merge_requests.merged_by_id
        LEFT OUTER JOIN repository_users AS repo_mergers ON repo_mergers.external_id = gl_mergers.gitlab_id::varchar
                                         AND repo_mergers.provider_id = #{provider_id}
        WHERE gitlab_merge_requests.title IS NOT NULL AND gitlab_merge_requests.body IS NOT NULL AND
              gitlab_merge_requests.created_at IS NOT NULL AND gitlab_merge_requests.updated_at IS NOT NULL
      SQL

      execute(<<~SQL.squish)
        INSERT INTO repository_pipelines(
          provider_id,
          repository_user_id,
          merge_request_id,
          external_id,
          external_project_id,
          status,
          web_url,
          details_url,
          ci_details,
          started_at,
          completed_at,
          created_at,
          updated_at
        )
        SELECT
          #{provider_id},
          repository_users.id,
          repository_merge_requests.id,
          gitlab_pipelines.gitlab_id,
          gitlab_pipelines.project_id,
          gitlab_pipelines.status,
          gitlab_pipelines.gitlab_html_url,
          gitlab_pipelines.details_url,
          gitlab_pipelines.ci_details,
          gitlab_pipelines.started_at,
          gitlab_pipelines.completed_at,
          gitlab_pipelines.created_at,
          gitlab_pipelines.updated_at
        FROM gitlab_pipelines
        LEFT OUTER JOIN gitlab_users ON gitlab_users.username = gitlab_pipelines.username
        LEFT OUTER JOIN repository_users ON repository_users.external_id = gitlab_users.gitlab_id::varchar
                                         AND repository_users.provider_id = #{provider_id}
        JOIN gitlab_merge_requests ON gitlab_merge_requests.id = gitlab_pipelines.gitlab_merge_request_id
        JOIN repository_merge_requests ON repository_merge_requests.web_url = gitlab_merge_requests.gitlab_html_url

      SQL
    end
  end

  def down
    # no-op, downing this migration won't do anything, but downing the preceding migrations will remove corresponding data
  end
end
