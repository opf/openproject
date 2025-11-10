# frozen_string_literal: true

# V9.5: Cross-Project Intelligence & Portfolio Analytics
# Creates dimension tables for data warehouse architecture

class CreateBimDataWarehouseDimensions < ActiveRecord::Migration[7.1]
  def change
    # Dimension: Projects (Type 2 SCD - Slowly Changing Dimension)
    create_table :bim_dim_projects do |t|
      t.references :project, foreign_key: true, null: false, index: true

      # Project attributes
      t.string :project_name, limit: 255
      t.string :project_identifier, limit: 100
      t.string :project_type, limit: 50          # commercial, residential, infrastructure, industrial
      t.string :project_size, limit: 20          # small, medium, large, mega
      t.string :region, limit: 100
      t.string :division, limit: 100
      t.string :client_segment, limit: 50        # public, private, government, mixed
      t.date :start_date
      t.date :target_completion_date
      t.decimal :total_budget, precision: 15, scale: 2
      t.boolean :active, default: true

      # Data warehouse metadata
      t.jsonb :metadata, default: {}

      # SCD Type 2 fields (track historical changes)
      t.timestamp :valid_from, null: false, default: -> { 'NOW()' }
      t.timestamp :valid_to, default: '9999-12-31 23:59:59'
      t.boolean :is_current, default: true

      # Benchmark opt-in
      t.boolean :contribute_to_benchmarks, default: false

      t.timestamps
    end

    # Indexes for dimension queries
    add_index :bim_dim_projects, [:project_id, :is_current], name: 'idx_dim_projects_current'
    add_index :bim_dim_projects, [:project_id, :valid_from], unique: true, name: 'idx_dim_projects_scd'
    add_index :bim_dim_projects, :project_type
    add_index :bim_dim_projects, :project_size
    add_index :bim_dim_projects, :region
    add_index :bim_dim_projects, :division
    add_index :bim_dim_projects, :client_segment
    add_index :bim_dim_projects, :contribute_to_benchmarks

    # Dimension: Time (pre-populated calendar dimension)
    create_table :bim_dim_time, primary_key: :date_key, id: :date do |t|
      t.integer :year, null: false
      t.integer :quarter, null: false              # 1-4
      t.integer :month, null: false                # 1-12
      t.integer :week, null: false                 # 1-53
      t.integer :day_of_week, null: false          # 0-6 (Sunday=0)
      t.integer :day_of_month, null: false         # 1-31
      t.integer :day_of_year, null: false          # 1-366
      t.boolean :is_weekend, default: false
      t.boolean :is_holiday, default: false
      t.string :holiday_name, limit: 100

      # Fiscal calendar
      t.integer :fiscal_year
      t.integer :fiscal_quarter
      t.integer :fiscal_month

      # Display formats
      t.string :year_month, limit: 7               # YYYY-MM
      t.string :year_quarter, limit: 7             # YYYY-Q1
      t.string :week_start_date, limit: 10         # YYYY-MM-DD
    end

    # Indexes for time dimension
    add_index :bim_dim_time, :year
    add_index :bim_dim_time, [:year, :month]
    add_index :bim_dim_time, [:year, :quarter]
    add_index :bim_dim_time, :year_month
    add_index :bim_dim_time, :is_weekend
    add_index :bim_dim_time, :is_holiday

    # Dimension: Users (Type 2 SCD)
    create_table :bim_dim_users do |t|
      t.references :user, foreign_key: true, null: false, index: true

      # User attributes
      t.string :user_name, limit: 255
      t.string :user_login, limit: 100
      t.string :user_email, limit: 255
      t.string :user_role, limit: 50
      t.string :department, limit: 100
      t.string :discipline, limit: 50              # architecture, structural, mep, civil

      # SCD Type 2 fields
      t.timestamp :valid_from, null: false, default: -> { 'NOW()' }
      t.timestamp :valid_to, default: '9999-12-31 23:59:59'
      t.boolean :is_current, default: true

      t.timestamps
    end

    # Indexes for user dimension
    add_index :bim_dim_users, [:user_id, :is_current], name: 'idx_dim_users_current'
    add_index :bim_dim_users, [:user_id, :valid_from], unique: true, name: 'idx_dim_users_scd'
    add_index :bim_dim_users, :user_role
    add_index :bim_dim_users, :department
    add_index :bim_dim_users, :discipline
  end
end
