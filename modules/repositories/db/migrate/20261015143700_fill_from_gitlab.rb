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
    return if !table_exists?(:gitlab_merge_requests) || !table_exists?(:gitlab_issues)

    mr_url = execute("SELECT gitlab_html_url FROM gitlab_merge_requests WHERE gitlab_html_url != '' ORDER BY id DESC LIMIT 1").first&.fetch("gitlab_html_url")
    issue_url = execute("SELECT gitlab_html_url FROM gitlab_issues WHERE gitlab_html_url != '' ORDER BY id DESC LIMIT 1").first&.fetch("gitlab_html_url")
    return if mr_url.blank? && issue_url.blank?

    base_url = URI.parse(mr_url.presence || issue_url).tap { |u| u.path = "" }
    # Read through Setting rather than the settings table so that ENV overrides are respected.
    # This requires the gitlab_integration plugin to stay registered until this migration is squashed.
    options = Setting.plugin_openproject_gitlab_integration.merge(url: base_url)
    ActiveRecord::Base.transaction do
      execute(<<~SQL.squish)
        INSERT INTO repository_providers (name, type, options, created_at, updated_at)
        VALUES('GitLab', 'Repositories::GitlabProvider', #{quote(options.to_json)}, NOW(), NOW())
      SQL

      provider_id = execute("SELECT id FROM repository_providers WHERE type = 'Repositories::GitlabProvider' LIMIT 1").first&.fetch("id")

      execute(<<~SQL.squish)
        INSERT INTO repository_users(provider_id, external_id, name, username, avatar_url, created_at, updated_at)
        SELECT DISTINCT ON (gitlab_id) #{provider_id}, gitlab_id, name, username, avatar_url, created_at, updated_at
        FROM gitlab_users
        ORDER BY gitlab_id, updated_at DESC
      SQL

      execute(<<~SQL.squish)
        INSERT INTO repository_issues(
          provider_id,
          repository_user_id,
          external_id,
          display_id,
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
          COALESCE(gitlab_issues.title, ''),
          COALESCE(gitlab_issues.body, ''),
          COALESCE(gitlab_issues.labels::jsonb, '[]'::jsonb),
          COALESCE(gitlab_issues.gitlab_updated_at, gitlab_issues.updated_at),
          gitlab_issues.created_at,
          gitlab_issues.updated_at
        FROM gitlab_issues
        LEFT OUTER JOIN gitlab_users ON gitlab_users.id = gitlab_issues.gitlab_user_id
        LEFT OUTER JOIN repository_users ON repository_users.external_id = gitlab_users.gitlab_id::varchar
                                         AND repository_users.provider_id = #{provider_id}
        WHERE gitlab_issues.gitlab_id IS NOT NULL
      SQL

      execute(<<~SQL.squish)
        INSERT INTO repository_merge_requests(
          provider_id,
          repository_user_id,
          external_id,
          display_id,
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
          gitlab_merge_requests.gitlab_id,
          gitlab_merge_requests.number,
          gitlab_merge_requests.gitlab_html_url,
          CASE WHEN gitlab_merge_requests.draft AND gitlab_merge_requests.state = 'opened' THEN 'draft'
               ELSE gitlab_merge_requests.state END,
          gitlab_merge_requests.repository,
          COALESCE(gitlab_merge_requests.title, ''),
          COALESCE(gitlab_merge_requests.body, ''),
          COALESCE(gitlab_merge_requests.labels::jsonb, '[]'::jsonb),
          COALESCE(gitlab_merge_requests.gitlab_updated_at, gitlab_merge_requests.updated_at),
          gitlab_merge_requests.created_at,
          gitlab_merge_requests.updated_at
        FROM gitlab_merge_requests
        LEFT OUTER JOIN gitlab_users ON gitlab_users.id = gitlab_merge_requests.gitlab_user_id
        LEFT OUTER JOIN repository_users ON repository_users.external_id = gitlab_users.gitlab_id::varchar
                                         AND repository_users.provider_id = #{provider_id}
        WHERE gitlab_merge_requests.gitlab_id IS NOT NULL
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
        LEFT OUTER JOIN (
          SELECT DISTINCT ON (username) username, gitlab_id
          FROM gitlab_users
          ORDER BY username, updated_at DESC
        ) pipeline_users ON pipeline_users.username = gitlab_pipelines.username
        LEFT OUTER JOIN repository_users ON repository_users.external_id = pipeline_users.gitlab_id::varchar
                                         AND repository_users.provider_id = #{provider_id}
        JOIN gitlab_merge_requests ON gitlab_merge_requests.id = gitlab_pipelines.gitlab_merge_request_id
        JOIN repository_merge_requests ON repository_merge_requests.web_url = gitlab_merge_requests.gitlab_html_url
      SQL

      execute(<<~SQL.squish)
        INSERT INTO repository_issues_work_packages(
          repository_issue_id,
          work_package_id
        )
        SELECT
          repository_issues.id,
          gitlab_issues_work_packages.work_package_id
        FROM gitlab_issues_work_packages
        JOIN gitlab_issues ON gitlab_issues.id = gitlab_issues_work_packages.gitlab_issue_id
        JOIN repository_issues ON repository_issues.web_url = gitlab_issues.gitlab_html_url
                              AND repository_issues.provider_id = #{provider_id}
      SQL

      execute(<<~SQL.squish)
        INSERT INTO repository_merge_requests_work_packages(
          repository_merge_request_id,
          work_package_id
        )
        SELECT
          repository_merge_requests.id,
          gitlab_merge_requests_work_packages.work_package_id
        FROM gitlab_merge_requests_work_packages
        JOIN gitlab_merge_requests ON gitlab_merge_requests.id = gitlab_merge_requests_work_packages.gitlab_merge_request_id
        JOIN repository_merge_requests ON repository_merge_requests.web_url = gitlab_merge_requests.gitlab_html_url
                                      AND repository_merge_requests.provider_id = #{provider_id}
      SQL
    end
  end

  # rubocop:disable-next Layout/LineLength
  def down
    provider_id = execute("SELECT id FROM repository_providers WHERE type = 'Repositories::GitlabProvider' LIMIT 1").first&.fetch("id")
    return if provider_id.nil?

    # We only need to delete the provider, all other rows will be deleted through cascading
    execute(<<~SQL.squish)
      DELETE FROM repository_providers WHERE id = #{provider_id}
    SQL
  end
end
