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

class CreateRepositoryPipelineJobs < ActiveRecord::Migration[8.1]
  def change
    create_jobs_table

    reversible do |direction|
      direction.up { move_ci_details_to_jobs }
      direction.down { move_jobs_to_ci_details }
    end

    remove_column :repository_pipelines, :ci_details, :jsonb
  end

  private

  def create_jobs_table
    create_table :repository_pipeline_jobs do |t|
      t.references :pipeline, null: false, index: false, foreign_key: { to_table: :repository_pipelines, on_delete: :cascade }

      t.string :external_id, null: false
      t.string :external_source_id, null: false
      t.string :name, null: false
      t.string :stage, null: false, default: ""
      t.string :status, null: false
      t.string :web_url, null: false
      t.datetime :started_at, null: false, precision: nil
      t.datetime :completed_at, precision: nil

      t.timestamps precision: nil, null: false

      t.index %i[pipeline_id external_id], unique: true
      t.index %i[pipeline_id external_source_id name]
    end
  end

  def move_ci_details_to_jobs
    execute <<~SQL.squish
      INSERT INTO repository_pipeline_jobs(
        pipeline_id,
        external_id,
        external_source_id,
        name,
        stage,
        status,
        web_url,
        started_at,
        completed_at,
        created_at,
        updated_at)
      SELECT p.id,
             build->>'id',
             'gitlab',
             COALESCE(build->>'name', ''),
             COALESCE(build->>'stage', ''),
             COALESCE(build->>'status', 'created'),
             regexp_replace(p.web_url, '/-/pipelines/.*$', '/-/jobs/') || (build->>'id'),
             COALESCE((build->>'created_at')::timestamp, (build->>'started_at')::timestamp, p.started_at, p.created_at),
             (build->>'finished_at')::timestamp,
             p.created_at,
             p.updated_at
      FROM repository_pipelines p
      CROSS JOIN LATERAL jsonb_array_elements(p.ci_details) AS build
      WHERE jsonb_typeof(p.ci_details) = 'array' AND build->>'id' IS NOT NULL
      ON CONFLICT (pipeline_id, external_id) DO NOTHING
    SQL
  end

  def move_jobs_to_ci_details
    execute <<~SQL.squish
      UPDATE repository_pipelines p
      SET ci_details = jobs.builds
      FROM (
        SELECT pipeline_id,
               jsonb_agg(jsonb_build_object('id', external_id::bigint,
                                            'name', name,
                                            'stage', stage,
                                            'status', status,
                                            'created_at', started_at,
                                            'finished_at', completed_at)
                         ORDER BY external_id::bigint) AS builds
        FROM repository_pipeline_jobs
        GROUP BY pipeline_id
      ) jobs
      WHERE jobs.pipeline_id = p.id
    SQL
  end
end
