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

class GeneralizeRepositoryResources < ActiveRecord::Migration[8.1]
  def change
    # GitHub does not consistently expose PR IDs (e.g. comment payloads only carry the issue id of a pull request)
    # This means we sometimes need to create "partial" PRs that have no known external ID yet
    change_column_null :repository_merge_requests, :external_id, true

    add_column :repository_issues, :external_project_id, :string
    add_column :repository_merge_requests, :external_project_id, :string
    add_column :repository_commits, :external_project_id, :string

    add_index :repository_issues, %i[provider_id external_project_id display_id]
    add_index :repository_merge_requests, %i[provider_id external_project_id display_id]
    add_index :repository_commits, %i[provider_id external_project_id sha]
  end
end
