# frozen_string_literal: true

# V9.5: Create benchmark and predictive modeling tables

class CreateBimBenchmarksAndPredictions < ActiveRecord::Migration[7.1]
  def change
    # Industry Benchmarks table
    create_table :bim_industry_benchmarks do |t|
      # Classification
      t.string :metric_type, null: false, limit: 50
      t.string :metric_name, null: false, limit: 100
      t.string :project_type, limit: 50
      t.string :project_size, limit: 20
      t.string :region, limit: 100
      t.string :discipline, limit: 50

      # Benchmark statistical values
      t.decimal :mean_value, precision: 15, scale: 4
      t.decimal :median_value, precision: 15, scale: 4
      t.decimal :std_dev, precision: 15, scale: 4
      t.decimal :percentile_10, precision: 15, scale: 4
      t.decimal :percentile_25, precision: 15, scale: 4
      t.decimal :percentile_50, precision: 15, scale: 4
      t.decimal :percentile_75, precision: 15, scale: 4
      t.decimal :percentile_90, precision: 15, scale: 4
      t.decimal :percentile_95, precision: 15, scale: 4
      t.decimal :percentile_99, precision: 15, scale: 4

      # Sample metadata
      t.integer :sample_size
      t.date :data_period_start
      t.date :data_period_end

      # Source information
      t.string :source, limit: 100                # ISO 19650, Internal, Industry Survey, BS EN 17412
      t.text :source_url
      t.decimal :confidence_level, precision: 5, scale: 2
      t.text :methodology_description

      # Validity period (SCD Type 2)
      t.date :valid_from, null: false
      t.date :valid_to, default: '9999-12-31'
      t.boolean :is_current, default: true

      # Additional metadata
      t.jsonb :metadata, default: {}
      t.text :notes

      t.timestamps
    end

    # Indexes for benchmarks
    add_index :bim_industry_benchmarks, [:metric_type, :metric_name], name: 'idx_benchmarks_metric'
    add_index :bim_industry_benchmarks, [:metric_type, :metric_name, :project_type, :project_size, :region, :valid_from],
              unique: true, name: 'idx_benchmarks_unique'
    add_index :bim_industry_benchmarks, :project_type
    add_index :bim_industry_benchmarks, :project_size
    add_index :bim_industry_benchmarks, :region
    add_index :bim_industry_benchmarks, :is_current
    add_index :bim_industry_benchmarks, [:valid_from, :valid_to], name: 'idx_benchmarks_validity'

    # Predictive Models table
    create_table :bim_predictive_models do |t|
      # Model identification
      t.string :model_name, null: false, limit: 100
      t.string :model_type, null: false, limit: 50  # time_series, regression, classification, anomaly_detection
      t.string :model_version, limit: 20
      t.text :description

      # Target metric
      t.string :target_metric_type, limit: 50
      t.string :target_metric_name, limit: 100
      t.string :target_scope, limit: 20            # portfolio, project, discipline

      # Training metadata
      t.date :training_start_date
      t.date :training_end_date
      t.integer :training_sample_size
      t.jsonb :training_features, default: []
      t.jsonb :training_parameters, default: {}

      # Model performance metrics
      t.decimal :accuracy, precision: 5, scale: 2
      t.decimal :precision_score, precision: 5, scale: 2
      t.decimal :recall_score, precision: 5, scale: 2
      t.decimal :f1_score, precision: 5, scale: 2
      t.decimal :rmse, precision: 15, scale: 4     # Root Mean Squared Error
      t.decimal :mae, precision: 15, scale: 4      # Mean Absolute Error
      t.decimal :mape, precision: 10, scale: 4     # Mean Absolute Percentage Error
      t.decimal :r_squared, precision: 5, scale: 4
      t.decimal :adjusted_r_squared, precision: 5, scale: 4

      # Model artifacts
      t.jsonb :model_parameters, default: {}
      t.jsonb :feature_importance, default: {}
      t.jsonb :hyperparameters, default: {}
      t.text :model_path                           # S3 or file path to serialized model
      t.text :model_framework                      # statsmodels, prophet, sklearn, tensorflow

      # Status and lifecycle
      t.string :status, limit: 20, default: 'training'  # training, validating, active, deprecated, failed
      t.timestamp :deployed_at
      t.timestamp :deprecated_at
      t.text :deprecation_reason

      # Audit
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.references :deployed_by, foreign_key: { to_table: :users }, null: true

      # Monitoring
      t.integer :prediction_count, default: 0
      t.decimal :avg_prediction_error, precision: 15, scale: 4
      t.timestamp :last_prediction_at

      t.timestamps
    end

    # Indexes for predictive models
    add_index :bim_predictive_models, :model_name
    add_index :bim_predictive_models, :model_type
    add_index :bim_predictive_models, :status
    add_index :bim_predictive_models, [:target_metric_type, :target_metric_name], name: 'idx_models_target_metric'
    add_index :bim_predictive_models, :deployed_at

    # Model Predictions table
    create_table :bim_model_predictions do |t|
      # Model reference
      t.references :predictive_model, foreign_key: { to_table: :bim_predictive_models }, null: false, index: true

      # Dimensions
      t.references :dim_project, foreign_key: { to_table: :bim_dim_projects }, index: true
      t.date :prediction_date, null: false
      t.date :target_date, null: false

      # Prediction details
      t.string :metric_type, null: false, limit: 50
      t.string :metric_name, null: false, limit: 100
      t.decimal :predicted_value, precision: 15, scale: 4
      t.decimal :confidence_interval_lower, precision: 15, scale: 4
      t.decimal :confidence_interval_upper, precision: 15, scale: 4
      t.decimal :confidence_level, precision: 5, scale: 2

      # Actual value (for validation after target_date)
      t.decimal :actual_value, precision: 15, scale: 4
      t.decimal :prediction_error, precision: 15, scale: 4
      t.decimal :absolute_error, precision: 15, scale: 4
      t.decimal :percentage_error, precision: 10, scale: 2

      # Input features used for prediction
      t.jsonb :input_features, default: {}
      t.jsonb :prediction_metadata, default: {}

      # Prediction quality
      t.string :prediction_quality, limit: 20       # excellent, good, fair, poor
      t.boolean :within_confidence_interval

      t.timestamps
    end

    # Indexes for predictions
    add_index :bim_model_predictions, [:predictive_model_id, :prediction_date], name: 'idx_predictions_model_date'
    add_index :bim_model_predictions, [:metric_type, :metric_name, :target_date], name: 'idx_predictions_metric_target'
    add_index :bim_model_predictions, [:prediction_date, :target_date], name: 'idx_predictions_dates'
    add_index :bim_model_predictions, :dim_project_id
    add_index :bim_model_predictions, :prediction_quality

    # Model Evaluation History table
    create_table :bim_model_evaluations do |t|
      t.references :predictive_model, foreign_key: { to_table: :bim_predictive_models }, null: false, index: true

      # Evaluation period
      t.date :evaluation_start_date
      t.date :evaluation_end_date
      t.integer :sample_size

      # Performance metrics
      t.decimal :rmse, precision: 15, scale: 4
      t.decimal :mae, precision: 15, scale: 4
      t.decimal :mape, precision: 10, scale: 4
      t.decimal :r_squared, precision: 5, scale: 4
      t.decimal :direction_accuracy, precision: 5, scale: 2  # % of times predicted trend direction correctly

      # Confidence interval coverage
      t.decimal :ci_coverage_actual, precision: 5, scale: 2   # % of actuals within predicted CI
      t.decimal :ci_coverage_expected, precision: 5, scale: 2 # Expected coverage (usually 95%)

      # Detailed results
      t.jsonb :evaluation_details, default: {}
      t.jsonb :error_distribution, default: {}

      # Recommendation
      t.string :recommendation, limit: 20           # keep, retrain, deprecate
      t.text :recommendation_reason

      t.references :evaluated_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    # Indexes for evaluations
    add_index :bim_model_evaluations, [:predictive_model_id, :created_at], name: 'idx_evaluations_model_time'
    add_index :bim_model_evaluations, :recommendation
  end
end
