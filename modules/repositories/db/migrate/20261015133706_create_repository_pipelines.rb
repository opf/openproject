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

class CreateRepositoryPipelines < ActiveRecord::Migration[8.1]
  def change
    create_table :repository_pipelines do |t|
      t.references :provider, null: false, foreign_key: { to_table: :repository_providers, on_delete: :cascade }
      t.references :merge_request, null: false, foreign_key: { to_table: :repository_merge_requests, on_delete: :cascade }
      t.references :repository_user, foreign_key: { on_delete: :nullify }

      t.bigint :external_id, null: false
      t.string :external_project_id, null: false
      t.string :status, null: false
      t.string :web_url, null: false
      t.string :details_url
      t.jsonb :ci_details
      t.datetime :started_at, precision: nil
      t.datetime :completed_at, precision: nil

      t.timestamps precision: nil, null: false
    end
  end
end
