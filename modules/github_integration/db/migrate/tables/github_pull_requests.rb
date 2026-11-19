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

require Rails.root.join("db/migrate/tables/base").to_s

class Tables::GithubPullRequests < Tables::Base
  def self.table(migration) # rubocop:disable Metrics/AbcSize
    create_table migration do |t|
      t.references :github_user
      t.references :merged_by

      t.bigint :github_id # may be null if we receive a comment and just know the html_url
      t.integer :number, null: false
      t.string :github_html_url, null: false
      t.string :state, null: false
      t.string :repository, null: false
      t.datetime :github_updated_at, precision: nil
      t.string :title
      t.text :body
      t.boolean :draft
      t.boolean :merged
      t.datetime :merged_at, precision: nil
      t.integer :comments_count
      t.integer :review_comments_count
      t.integer :additions_count
      t.integer :deletions_count
      t.integer :changed_files_count
      t.json :labels # [{name, color}]
      t.timestamps precision: nil
      t.string :repository_html_url
      t.text :merge_commit_sha
    end
  end
end
