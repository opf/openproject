# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class CreateBimDashboards < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_dashboards do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.references :user, null: true, foreign_key: { on_delete: :cascade }

      t.string :name, null: false, limit: 255
      t.text :description
      t.boolean :is_default, default: false, null: false
      t.boolean :is_public, default: false, null: false

      # Grid layout configuration (e.g., {"cols": 12, "rowHeight": 100})
      t.jsonb :layout_config, default: {}, null: false

      # Dashboard-level settings (e.g., refresh interval, filters)
      t.jsonb :settings, default: {}, null: false

      t.timestamps null: false
    end

    # Indexes
    add_index :bim_dashboards, [:project_id, :is_default], name: 'index_dashboards_on_project_default'
    add_index :bim_dashboards, [:project_id, :user_id], name: 'index_dashboards_on_project_user'
    add_index :bim_dashboards, :is_public, name: 'index_dashboards_on_public'

    # GIN index for JSONB columns
    add_index :bim_dashboards, :layout_config, using: :gin, name: 'index_dashboards_on_layout_config'
    add_index :bim_dashboards, :settings, using: :gin, name: 'index_dashboards_on_settings'

    # Constraint: Only one default dashboard per project
    add_index :bim_dashboards, :project_id,
              unique: true,
              where: 'is_default = true',
              name: 'index_dashboards_unique_default_per_project'
  end
end
