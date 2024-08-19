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
class GitlabIntegrationModels < ActiveRecord::Migration[6.1]
  # rubocop:disable Metrics/AbcSize
  def change
    create_table :gitlab_merge_requests do |t|
      t.references :gitlab_user
      t.references :merged_by

      t.bigint :gitlab_id, unique: true
      t.integer :number, null: false
      t.string :gitlab_html_url, null: false, unique: true
      t.string :state, null: false
      t.string :repository, null: false
      t.datetime :gitlab_updated_at
      t.string :title
      t.text :body
      t.boolean :draft
      t.boolean :merged
      t.datetime :merged_at
      t.json :labels # [{name, color}]

      t.timestamps
    end

    create_join_table :gitlab_merge_requests, :work_packages do |t|
      t.index :gitlab_merge_request_id, name: "gitlab_mr_wp_mr_id"
      t.index %i[gitlab_merge_request_id work_package_id],
              unique: true,
              name: "unique_index_gl_mrs_wps_on_gl_mr_id_and_wp_id"
    end

    create_table :gitlab_users do |t|
      t.bigint :gitlab_id, null: false, unique: true
      t.string :gitlab_name, null: false
      t.string :gitlab_username, null: false
      t.string :gitlab_email, null: false
      t.string :gitlab_avatar_url, null: false

      t.timestamps
    end

    create_table :gitlab_pipelines do |t|
      t.references :gitlab_merge_request, null: false

      t.bigint :gitlab_id, null: false, unique: true
      t.string :gitlab_html_url, null: false
      t.bigint :project_id, null: false
      t.string :gitlab_user_avatar_url, null: false
      t.string :status, null: false
      t.string :name, null: false
      t.string :details_url
      t.json :ci_details
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
  end
  # rubocop:enable Metrics/AbcSize
end
