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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class CreateGitlabBranches < ActiveRecord::Migration[8.1]
  def change
    create_table :gitlab_branches do |t|
      t.references :work_package, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :gitlab_project_id, null: false
      t.string :namespace, null: false
      t.string :namespace_html_url, null: false
      t.string :name, null: false
      t.string :gitlab_html_url, null: false
      t.string :repository, null: false
      t.references :gitlab_user

      t.timestamps

      t.index %i[gitlab_project_id name], unique: true
    end
  end
end
