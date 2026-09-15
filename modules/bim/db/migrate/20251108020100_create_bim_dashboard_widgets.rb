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

class CreateBimDashboardWidgets < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_dashboard_widgets do |t|
      t.references :dashboard, null: false, foreign_key: { to_table: :bim_dashboards, on_delete: :cascade }, index: true

      # Widget type enum: model_count, clash_summary, issue_trend, progress_chart, etc.
      t.integer :widget_type, null: false, default: 0

      t.string :title, limit: 255
      t.text :description

      # Position in grid: {"x": 0, "y": 0}
      t.jsonb :position, null: false, default: {}

      # Size in grid units: {"width": 4, "height": 3}
      t.jsonb :size, null: false, default: {}

      # Widget-specific configuration: filters, chart type, data source, etc.
      t.jsonb :config, default: {}, null: false

      # Cached widget data (optional, for performance)
      t.jsonb :cached_data, default: {}

      # Cache timestamp
      t.datetime :cached_at

      # Refresh interval in seconds (null = no auto-refresh)
      t.integer :refresh_interval

      t.timestamps null: false
    end

    # Indexes
    add_index :bim_dashboard_widgets, :widget_type, name: 'index_widgets_on_type'
    add_index :bim_dashboard_widgets, [:dashboard_id, :widget_type], name: 'index_widgets_on_dashboard_type'

    # GIN indexes for JSONB columns
    add_index :bim_dashboard_widgets, :position, using: :gin, name: 'index_widgets_on_position'
    add_index :bim_dashboard_widgets, :size, using: :gin, name: 'index_widgets_on_size'
    add_index :bim_dashboard_widgets, :config, using: :gin, name: 'index_widgets_on_config'
    add_index :bim_dashboard_widgets, :cached_data, using: :gin, name: 'index_widgets_on_cached_data'

    # Check constraint for widget_type enum range
    add_check_constraint :bim_dashboard_widgets,
                         'widget_type >= 0 AND widget_type <= 20',
                         name: 'widget_type_range'
  end
end
