# frozen_string_literal: true

class CreateBimPortfolioMetrics < ActiveRecord::Migration[7.1]
  def change
    create_table :bim_portfolio_metrics do |t|
      # Metric identification
      t.string :metric_type, null: false, limit: 50
      t.string :metric_name, null: false, limit: 100
      t.date :metric_date, null: false

      # Scope (portfolio-wide or project-specific)
      t.references :project, foreign_key: true, type: :bigint, index: true
      t.string :scope, null: false, limit: 20, default: 'project' # portfolio, project, discipline

      # Metric values
      t.decimal :value, precision: 15, scale: 4
      t.jsonb :details, default: {}
      t.jsonb :breakdown, default: {}

      # Aggregation metadata
      t.integer :sample_count, default: 0
      t.string :aggregation_method, limit: 20 # sum, avg, count, max, min
      t.string :unit, limit: 20 # percentage, count, days, hours

      # Categorization
      t.string :category, limit: 50 # performance, quality, progress, collaboration
      t.string :discipline, limit: 50 # architectural, structural, mep
      t.string :tags, array: true, default: []

      # Trend indicators
      t.decimal :previous_value, precision: 15, scale: 4
      t.decimal :change_amount, precision: 15, scale: 4
      t.decimal :change_percentage, precision: 10, scale: 2
      t.string :trend, limit: 20 # improving, declining, stable

      # Status
      t.string :status, limit: 20 # good, warning, critical
      t.decimal :threshold_good, precision: 15, scale: 4
      t.decimal :threshold_warning, precision: 15, scale: 4

      # Audit
      t.datetime :collected_at, null: false
      t.references :collected_by, foreign_key: { to_table: :users }, type: :bigint
      t.boolean :stale, default: false

      t.timestamps
    end

    # Indexes for efficient queries
    add_index :bim_portfolio_metrics, [:metric_type, :metric_date], name: 'idx_portfolio_metrics_type_date'
    add_index :bim_portfolio_metrics, [:project_id, :metric_date], name: 'idx_portfolio_metrics_project_date'
    add_index :bim_portfolio_metrics, [:scope, :metric_date], name: 'idx_portfolio_metrics_scope_date'
    add_index :bim_portfolio_metrics, :category
    add_index :bim_portfolio_metrics, :discipline
    add_index :bim_portfolio_metrics, :status
    add_index :bim_portfolio_metrics, :metric_date
    add_index :bim_portfolio_metrics, :collected_at
    add_index :bim_portfolio_metrics, :details, using: :gin
    add_index :bim_portfolio_metrics, :breakdown, using: :gin
    add_index :bim_portfolio_metrics, :tags, using: :gin

    # Unique constraint to prevent duplicate metrics
    add_index :bim_portfolio_metrics,
              [:metric_type, :metric_name, :metric_date, :project_id, :scope],
              unique: true,
              name: 'idx_portfolio_metrics_unique'
  end
end
