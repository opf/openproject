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

class CreateRepositoryMergeRequestPipelines < ActiveRecord::Migration[8.1]
  def up
    create_table :repository_merge_request_pipelines do |t|
      t.references :merge_request, null: false, index: false,
                                   foreign_key: { to_table: :repository_merge_requests, on_delete: :cascade }
      t.references :pipeline, null: false, foreign_key: { to_table: :repository_pipelines, on_delete: :cascade }

      t.timestamps precision: nil, null: false

      t.index %i[merge_request_id pipeline_id], unique: true
    end

    link_merge_requests_to_deduplicated_pipelines
    delete_discarded_duplicates

    remove_column :repository_pipelines, :merge_request_id
    add_index :repository_pipelines, %i[provider_id external_project_id external_id], unique: true
    remove_index :repository_pipelines, :provider_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def link_merge_requests_to_deduplicated_pipelines
    execute <<~SQL.squish
      INSERT INTO repository_merge_request_pipelines (merge_request_id, pipeline_id, created_at, updated_at)
      SELECT merge_request_id,
             FIRST_VALUE(id) OVER (PARTITION BY provider_id, external_project_id, external_id
                                   ORDER BY updated_at DESC, id DESC),
             created_at,
             updated_at
      FROM repository_pipelines
      ON CONFLICT (merge_request_id, pipeline_id) DO NOTHING
    SQL
  end

  def delete_discarded_duplicates
    execute <<~SQL.squish
      DELETE FROM repository_pipelines
      WHERE NOT EXISTS (SELECT 1 FROM repository_merge_request_pipelines mrp WHERE mrp.pipeline_id = repository_pipelines.id)
    SQL
  end
end
