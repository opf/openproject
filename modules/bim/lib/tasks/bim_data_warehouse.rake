# frozen_string_literal: true

namespace :bim do
  namespace :data_warehouse do
    desc 'Initialize data warehouse (populate dimensions and seed benchmarks)'
    task initialize: :environment do
      puts "\n=== Initializing BIM Data Warehouse ===\n"

      Rake::Task['bim:data_warehouse:populate_time_dimension'].invoke
      Rake::Task['bim:data_warehouse:sync_project_dimension'].invoke
      Rake::Task['bim:data_warehouse:sync_user_dimension'].invoke
      Rake::Task['bim:data_warehouse:seed_benchmarks'].invoke

      puts "\n✓ Data warehouse initialization complete"
    end

    desc 'Populate time dimension table'
    task populate_time_dimension: :environment do
      start_date = ENV['START_DATE'] ? Date.parse(ENV['START_DATE']) : Date.new(2020, 1, 1)
      end_date = ENV['END_DATE'] ? Date.parse(ENV['END_DATE']) : Date.new(2030, 12, 31)
      fiscal_year_start = ENV['FISCAL_YEAR_START']&.to_i || 1

      puts "Populating time dimension from #{start_date} to #{end_date}..."
      puts "Fiscal year start month: #{fiscal_year_start}"

      Bim::DimTime.populate!(
        start_date: start_date,
        end_date: end_date,
        fiscal_year_start_month: fiscal_year_start
      )

      count = Bim::DimTime.count
      puts "✓ Time dimension populated with #{count} dates"

      # Mark holidays if provided
      if ENV['HOLIDAYS_FILE']
        holidays = load_holidays_from_file(ENV['HOLIDAYS_FILE'])
        Bim::DimTime.mark_holidays!(holidays)
        puts "✓ Marked #{holidays.size} holidays"
      end
    end

    desc 'Sync project dimension with current projects'
    task sync_project_dimension: :environment do
      puts "Synchronizing project dimension..."

      projects = Project.where(active: true)
      synced = 0
      errors = 0

      projects.each do |project|
        begin
          Bim::DimProject.for_project(project)
          synced += 1
        rescue => e
          errors += 1
          puts "  Error syncing project #{project.id}: #{e.message}"
        end
      end

      puts "✓ Synced #{synced} projects to dimension table"
      puts "⚠ #{errors} errors" if errors > 0
    end

    desc 'Sync user dimension with current users'
    task sync_user_dimension: :environment do
      puts "Synchronizing user dimension..."

      users = User.where(status: User::STATUSES[:active])
      synced = 0
      errors = 0

      users.each do |user|
        begin
          Bim::DimUser.for_user(user)
          synced += 1
        rescue => e
          errors += 1
          puts "  Error syncing user #{user.id}: #{e.message}"
        end
      end

      puts "✓ Synced #{synced} users to dimension table"
      puts "⚠ #{errors} errors" if errors > 0
    end

    desc 'Seed industry benchmarks'
    task seed_benchmarks: :environment do
      puts "Seeding industry benchmarks..."

      Bim::IndustryBenchmark.seed_iso_19650_benchmarks!

      count = Bim::IndustryBenchmark.current.count
      puts "✓ Seeded #{count} industry benchmarks"
    end

    desc 'Calculate statistics for all portfolio metrics'
    task calculate_statistics: :environment do
      puts "\n=== Calculating Portfolio Metrics Statistics ===\n"

      metric_types = Bim::PortfolioMetric.distinct.pluck(:metric_type, :metric_name)

      metric_types.each do |metric_type, metric_name|
        puts "Processing #{metric_type}/#{metric_name}..."

        service = Bim::Services::StatisticalAnalysisService.new(
          metric_type: metric_type,
          metric_name: metric_name
        )

        # Calculate statistics for last 90 days
        end_date = Date.current
        start_date = end_date - 90.days

        analysis = service.analyze_time_series(
          start_date: start_date,
          end_date: end_date
        )

        if analysis[:statistics]
          puts "  Mean: #{analysis[:statistics][:mean_value]&.round(2)}"
          puts "  Std Dev: #{analysis[:statistics][:std_dev]&.round(2)}"
          puts "  Trend: #{analysis[:trend][:direction]}"
          puts "  Anomalies detected: #{analysis[:anomalies]&.size || 0}"
        end
      end

      puts "\n✓ Statistics calculation complete"
    end

    desc 'Update dimension foreign keys for existing metrics'
    task update_dimension_keys: :environment do
      puts "Updating dimension foreign keys for portfolio metrics..."

      updated = 0
      errors = 0

      Bim::PortfolioMetric.where(dim_project_id: nil).find_each do |metric|
        begin
          next unless metric.project_id

          dim_project = Bim::DimProject.where(project_id: metric.project_id, is_current: true).first
          dim_time = Bim::DimTime.for_date(metric.metric_date)
          dim_user = metric.collected_by ? Bim::DimUser.for_user(metric.collected_by) : nil

          metric.update_columns(
            dim_project_id: dim_project&.id,
            dim_time_id: dim_time&.date_key,
            dim_user_id: dim_user&.id
          )

          updated += 1
        rescue => e
          errors += 1
          puts "  Error updating metric #{metric.id}: #{e.message}"
        end

        print "\r  Updated #{updated} metrics" if updated % 100 == 0
      end

      puts "\n✓ Updated #{updated} portfolio metrics with dimension keys"
      puts "⚠ #{errors} errors" if errors > 0
    end

    desc 'Detect anomalies in portfolio metrics'
    task detect_anomalies: :environment do
      metric_type = ENV['METRIC_TYPE']
      metric_name = ENV['METRIC_NAME']
      method = ENV['METHOD'] || 'zscore'
      threshold = ENV['THRESHOLD']&.to_f || 3.0

      raise 'METRIC_TYPE and METRIC_NAME required' unless metric_type && metric_name

      puts "\n=== Detecting Anomalies: #{metric_type}/#{metric_name} ===\n"
      puts "Method: #{method}"
      puts "Threshold: #{threshold}\n\n"

      service = Bim::Services::StatisticalAnalysisService.new(
        metric_type: metric_type,
        metric_name: metric_name
      )

      end_date = Date.current
      start_date = end_date - 90.days

      anomalies = service.detect_anomalies_for_period(
        start_date: start_date,
        end_date: end_date,
        method: method,
        threshold: threshold
      )

      if anomalies.any?
        puts "Found #{anomalies.size} anomalies:\n"
        anomalies.each do |anomaly|
          puts "  #{anomaly[:date]}: #{anomaly[:value].round(2)} (#{anomaly[:anomaly_type]}, z-score: #{anomaly[:z_score]&.round(2)})"
        end

        # Mark anomalies in database
        if ENV['MARK'] == 'true'
          marked = 0
          anomalies.each do |anomaly|
            metric = Bim::PortfolioMetric
                     .for_metric_type(metric_type)
                     .for_metric_name(metric_name)
                     .for_date(anomaly[:date])
                     .first

            if metric
              metric.update!(
                is_anomaly: true,
                anomaly_score: anomaly[:z_score]&.abs,
                anomaly_type: anomaly[:anomaly_type]
              )
              marked += 1
            end
          end
          puts "\n✓ Marked #{marked} anomalies in database"
        else
          puts "\nTo mark anomalies in database, run: rake bim:data_warehouse:detect_anomalies MARK=true"
        end
      else
        puts "No anomalies detected"
      end
    end

    desc 'Generate benchmark comparison report'
    task benchmark_report: :environment do
      puts "\n=== Portfolio Benchmark Comparison Report ===\n"
      puts "Date: #{Date.current}\n\n"

      # Get current portfolio metrics
      current_metrics = Bim::PortfolioMetric
                        .portfolio_wide
                        .for_date(Date.current)
                        .fresh

      if current_metrics.empty?
        puts "No current metrics available. Run portfolio collection first."
        exit
      end

      current_metrics.group_by(&:metric_type).each do |metric_type, metrics|
        puts "#{metric_type.upcase} Metrics:"
        puts "=" * 80

        metrics.each do |metric|
          service = Bim::Services::StatisticalAnalysisService.new(
            metric_type: metric.metric_type,
            metric_name: metric.metric_name
          )

          comparison = service.compare_to_benchmark(metric.value.to_f)

          if comparison.any?
            puts "\n  #{metric.metric_name}:"
            puts "    Current Value: #{metric.formatted_value}"
            puts "    Benchmark Mean: #{comparison[:benchmark_mean]&.round(2)}"
            puts "    Variance: #{comparison[:variance_from_benchmark]&.round(2)}%"
            puts "    Percentile Rank: #{comparison[:percentile_rank]}"
            puts "    Performance: #{comparison[:performance_category]&.humanize}"
            puts "    Source: #{comparison[:benchmark_source]}"
          else
            puts "\n  #{metric.metric_name}: #{metric.formatted_value} (no benchmark available)"
          end
        end

        puts "\n"
      end
    end

    desc 'Export data warehouse statistics'
    task export_stats: :environment do
      puts "\n=== Data Warehouse Statistics ===\n"

      stats = {
        'Dimension Tables' => {
          'Projects': Bim::DimProject.current.count,
          'Time Dates': Bim::DimTime.count,
          'Users': Bim::DimUser.current.count
        },
        'Fact Tables' => {
          'Portfolio Metrics': Bim::PortfolioMetric.count,
          'Fresh Metrics': Bim::PortfolioMetric.fresh.count,
          'Stale Metrics': Bim::PortfolioMetric.stale.count
        },
        'Benchmarks' => {
          'Industry Benchmarks': Bim::IndustryBenchmark.current.count,
          'Benchmark Sources': Bim::IndustryBenchmark.current.distinct.pluck(:source).size
        },
        'Coverage' => {
          'Earliest Metric': Bim::PortfolioMetric.order(:metric_date).first&.metric_date,
          'Latest Metric': Bim::PortfolioMetric.order(metric_date: :desc).first&.metric_date,
          'Metric Types': Bim::PortfolioMetric.distinct.count(:metric_type),
          'Unique Metrics': Bim::PortfolioMetric.distinct.pluck(:metric_type, :metric_name).size
        }
      }

      stats.each do |category, values|
        puts "#{category}:"
        values.each do |key, value|
          puts "  #{key}: #{value}"
        end
        puts ""
      end

      # Data quality
      metrics_with_stats = Bim::PortfolioMetric.where.not(std_dev: nil).count
      total_metrics = Bim::PortfolioMetric.count
      completeness = total_metrics > 0 ? (metrics_with_stats.to_f / total_metrics * 100).round(2) : 0

      puts "Data Quality:"
      puts "  Metrics with Statistics: #{metrics_with_stats} / #{total_metrics} (#{completeness}%)"

      anomaly_count = Bim::PortfolioMetric.where(is_anomaly: true).count
      puts "  Anomalies Detected: #{anomaly_count}"
      puts ""
    end

    desc 'Cleanup old dimension records'
    task cleanup_dimensions: :environment do
      older_than = ENV['OLDER_THAN'] ? Date.parse(ENV['OLDER_THAN']) : 2.years.ago.to_date

      puts "Cleaning up dimension records older than #{older_than}..."

      # Delete old project dimension records (not current)
      deleted_projects = Bim::DimProject.where(is_current: false)
                                        .where('valid_to < ?', older_than)
                                        .delete_all

      # Delete old user dimension records (not current)
      deleted_users = Bim::DimUser.where(is_current: false)
                                   .where('valid_to < ?', older_than)
                                   .delete_all

      puts "✓ Deleted #{deleted_projects} old project dimension records"
      puts "✓ Deleted #{deleted_users} old user dimension records"
    end

    private

    def load_holidays_from_file(file_path)
      # Expected format: CSV with date,name columns
      # 2025-01-01,New Year's Day
      # 2025-12-25,Christmas Day

      holidays = {}

      File.readlines(file_path).each do |line|
        next if line.strip.empty? || line.start_with?('#')

        date_str, name = line.strip.split(',', 2)
        date = Date.parse(date_str)
        holidays[date] = name
      end

      holidays
    rescue => e
      puts "Error loading holidays file: #{e.message}"
      {}
    end
  end
end
