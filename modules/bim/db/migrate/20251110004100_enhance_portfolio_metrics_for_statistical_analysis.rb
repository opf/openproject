# frozen_string_literal: true

# V9.5: Add statistical analysis, benchmarking, and forecasting fields to portfolio metrics

class EnhancePortfolioMetricsForStatisticalAnalysis < ActiveRecord::Migration[7.1]
  def change
    # Add dimension foreign keys
    add_reference :bim_portfolio_metrics, :dim_project, foreign_key: { to_table: :bim_dim_projects }, index: true
    add_reference :bim_portfolio_metrics, :dim_time, foreign_key: { to_table: :bim_dim_time, primary_key: :date_key, type: :date }, index: true
    add_reference :bim_portfolio_metrics, :dim_user, foreign_key: { to_table: :bim_dim_users }, index: true

    # Statistical measures
    add_column :bim_portfolio_metrics, :sample_size, :integer
    add_column :bim_portfolio_metrics, :mean_value, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :median_value, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :std_dev, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :variance, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :min_value, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :max_value, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :percentile_25, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :percentile_75, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :percentile_90, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :confidence_interval_lower, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :confidence_interval_upper, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :confidence_level, :decimal, precision: 5, scale: 2, default: 95.0

    # Benchmark comparison
    add_column :bim_portfolio_metrics, :benchmark_value, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :benchmark_source, :string, limit: 100
    add_column :bim_portfolio_metrics, :variance_from_benchmark, :decimal, precision: 10, scale: 2
    add_column :bim_portfolio_metrics, :percentile_rank, :decimal, precision: 5, scale: 2

    # Forecasting
    add_column :bim_portfolio_metrics, :forecast_next_period, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :forecast_confidence, :decimal, precision: 5, scale: 2
    add_column :bim_portfolio_metrics, :forecast_model, :string, limit: 50

    # Time series analysis
    add_column :bim_portfolio_metrics, :moving_avg_7d, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :moving_avg_30d, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :moving_avg_90d, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :exponential_smoothing, :decimal, precision: 15, scale: 4
    add_column :bim_portfolio_metrics, :seasonality_factor, :decimal, precision: 10, scale: 6

    # Anomaly detection
    add_column :bim_portfolio_metrics, :is_anomaly, :boolean, default: false
    add_column :bim_portfolio_metrics, :anomaly_score, :decimal, precision: 10, scale: 6
    add_column :bim_portfolio_metrics, :anomaly_type, :string, limit: 50  # spike, drop, trend_change, outlier

    # Data quality
    add_column :bim_portfolio_metrics, :data_quality_score, :decimal, precision: 5, scale: 2
    add_column :bim_portfolio_metrics, :data_completeness, :decimal, precision: 5, scale: 2
    add_column :bim_portfolio_metrics, :validation_status, :string, limit: 20, default: 'pending'
    add_column :bim_portfolio_metrics, :validation_errors, :jsonb, default: {}

    # Indexes for new fields
    add_index :bim_portfolio_metrics, :dim_project_id
    add_index :bim_portfolio_metrics, :dim_time_id
    add_index :bim_portfolio_metrics, :dim_user_id
    add_index :bim_portfolio_metrics, :is_anomaly
    add_index :bim_portfolio_metrics, :validation_status
    add_index :bim_portfolio_metrics, [:metric_type, :metric_name, :dim_time_id], name: 'idx_portfolio_metrics_time_series'
    add_index :bim_portfolio_metrics, [:dim_project_id, :metric_type, :metric_date], name: 'idx_portfolio_metrics_project_metric'
  end
end
