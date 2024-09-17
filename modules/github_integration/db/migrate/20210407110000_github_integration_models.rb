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

class GithubIntegrationModels < ActiveRecord::Migration[6.1]
  # rubocop:disable Metrics/AbcSize
  def change
    # see https://docs.github.com/en/rest/reference/pulls
    create_table :github_pull_requests do |t|
      t.references :github_user
      t.references :merged_by

      t.bigint :github_id, unique: true # may be null if we receive a comment and just know the html_url
      t.integer :number, null: false
      t.string :github_html_url, null: false, unique: true
      t.string :state, null: false
      t.string :repository, null: false
      t.datetime :github_updated_at
      t.string :title
      t.text :body
      t.boolean :draft
      t.boolean :merged
      t.datetime :merged_at
      t.integer :comments_count
      t.integer :review_comments_count
      t.integer :additions_count
      t.integer :deletions_count
      t.integer :changed_files_count
      t.json :labels # [{name, color}]
      t.timestamps
    end

    create_join_table :github_pull_requests, :work_packages do |t|
      t.index :github_pull_request_id, name: "github_pr_wp_pr_id"
      t.index %i[github_pull_request_id work_package_id],
              unique: true,
              name: "unique_index_gh_prs_wps_on_gh_pr_id_and_wp_id"
    end

    # see: https://docs.github.com/en/rest/reference/users
    create_table :github_users do |t|
      t.bigint :github_id, null: false, unique: true
      t.string :github_login, null: false
      t.string :github_html_url, null: false
      t.string :github_avatar_url, null: false

      t.timestamps
    end

    # see: https://docs.github.com/en/rest/reference/checks
    create_table :github_check_runs do |t|
      t.references :github_pull_request, null: false

      t.bigint :github_id, null: false, unique: true
      t.string :github_html_url, null: false
      t.bigint :app_id, null: false
      t.string :github_app_owner_avatar_url, null: false
      t.string :status, null: false
      t.string :name, null: false
      t.string :conclusion
      t.string :output_title
      t.string :output_summary
      t.string :details_url
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
  end
  # rubocop:enable Metrics/AbcSize
end
