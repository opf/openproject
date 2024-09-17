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
class AddGitlabIssues < ActiveRecord::Migration[7.0]
  def change
    create_table :gitlab_issues do |t|
      t.references :gitlab_user

      t.bigint :gitlab_id, unique: true
      t.integer :number, null: false
      t.string :gitlab_html_url, null: false, unique: true
      t.string :state, null: false
      t.string :repository, null: false
      t.datetime :gitlab_updated_at
      t.string :title
      t.text :body
      t.json :labels # [{name, color}]

      t.timestamps
    end

    create_join_table :gitlab_issues, :work_packages do |t|
      t.index :gitlab_issue_id, name: "gitlab_issues_wp_issue_id"
      t.index %i[gitlab_issue_id work_package_id],
              unique: true,
              name: "unique_index_gl_issues_wps_on_gl_issue_id_and_wp_id"
    end
  end
end
