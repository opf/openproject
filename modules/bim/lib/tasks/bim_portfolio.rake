# frozen_string_literal: true

namespace :bim do
  namespace :portfolio do
    desc 'Collect portfolio metrics for the current date'
    task collect: :environment do
      date = ENV['DATE'] ? Date.parse(ENV['DATE']) : Date.current
      project_ids = ENV['PROJECT_IDS']&.split(',')

      projects = if project_ids
                   Project.where(id: project_ids, active: true)
                 else
                   Project.where(active: true)
                 end

      puts "\n=== Collecting Portfolio Metrics ===\n"
      puts "Date: #{date}"
      puts "Projects: #{projects.count}"
      puts ""

      analytics = Bim::Services::PortfolioAnalyticsService.new(
        date: date,
        projects: projects
      )

      results = analytics.collect_all_metrics(user: User.system)

      puts "\n=== Collection Results ===\n"
      puts "✓ Metrics collected: #{results[:metrics_collected]}"
      puts "✓ Projects processed: #{results[:projects_processed]}"
      puts "✓ Collected at: #{results[:collected_at]}"

      if results[:errors].any?
        puts "\n⚠ Errors encountered:"
        results[:errors].each do |error|
          puts "  - #{error[:project]}: #{error[:error]}"
        end
      else
        puts "\n✓ No errors"
      end

      puts "\n"
    end

    desc 'Display portfolio statistics and summary'
    task stats: :environment do
      puts "\n=== Portfolio Metrics Statistics ===\n"

      total_metrics = Bim::PortfolioMetric.count
      fresh_metrics = Bim::PortfolioMetric.fresh.count
      stale_metrics = Bim::PortfolioMetric.stale.count

      puts "Total metrics: #{total_metrics}"
      puts "Fresh metrics: #{fresh_metrics}"
      puts "Stale metrics: #{stale_metrics}"

      if total_metrics > 0
        puts "\nBreakdown by scope:"
        Bim::PortfolioMetric.group(:scope).count.each do |scope, count|
          percentage = (count.to_f / total_metrics * 100).round(2)
          puts "  #{scope.to_s.ljust(20)}: #{count.to_s.rjust(6)} (#{percentage}%)"
        end

        puts "\nBreakdown by category:"
        Bim::PortfolioMetric.group(:category).count.each do |category, count|
          percentage = (count.to_f / total_metrics * 100).round(2)
          puts "  #{category.to_s.ljust(20)}: #{count.to_s.rjust(6)} (#{percentage}%)"
        end

        puts "\nBreakdown by status:"
        Bim::PortfolioMetric.group(:status).count.each do |status, count|
          percentage = (count.to_f / total_metrics * 100).round(2)
          symbol = case status
                   when 'good' then '✓'
                   when 'warning' then '⚠'
                   when 'critical' then '✗'
                   else ' '
                   end
          puts "  #{symbol} #{status.to_s.capitalize.ljust(18)}: #{count.to_s.rjust(6)} (#{percentage}%)"
        end

        puts "\nBreakdown by trend:"
        Bim::PortfolioMetric.fresh.group(:trend).count.each do |trend, count|
          percentage = (count.to_f / fresh_metrics * 100).round(2)
          symbol = case trend
                   when 'improving' then '↑'
                   when 'declining' then '↓'
                   when 'stable' then '→'
                   else ' '
                   end
          puts "  #{symbol} #{trend.to_s.capitalize.ljust(18)}: #{count.to_s.rjust(6)} (#{percentage}%)"
        end

        puts "\nDate range:"
        oldest = Bim::PortfolioMetric.order(metric_date: :asc).first
        newest = Bim::PortfolioMetric.order(metric_date: :desc).first
        puts "  Oldest metric: #{oldest.metric_date}"
        puts "  Newest metric: #{newest.metric_date}"

        latest_collection = Bim::PortfolioMetric.order(collected_at: :desc).first
        puts "\nLatest collection: #{latest_collection.collected_at.strftime('%Y-%m-%d %H:%M:%S')}"

        # Show top critical metrics
        critical_metrics = Bim::PortfolioMetric.fresh.critical_status.limit(5)
        if critical_metrics.any?
          puts "\n⚠ Critical Metrics (showing up to 5):"
          critical_metrics.each do |metric|
            project_name = metric.project ? metric.project.name : 'Portfolio-wide'
            puts "  - #{metric.metric_type}/#{metric.metric_name} (#{project_name}): #{metric.formatted_value}"
          end
        end
      end

      puts "\n"
    end

    desc 'Show portfolio dashboard summary'
    task dashboard: :environment do
      date = ENV['DATE'] ? Date.parse(ENV['DATE']) : Date.current

      puts "\n=== Portfolio Dashboard (#{date}) ===\n"

      summary = Bim::PortfolioMetric.dashboard_summary(scope: 'portfolio', date: date)

      puts "Total metrics: #{summary[:total_metrics]}"
      puts ""

      puts "By category:"
      summary[:by_category].each do |category, count|
        puts "  #{category.to_s.ljust(20)}: #{count}"
      end
      puts ""

      puts "By status:"
      summary[:by_status].each do |status, count|
        symbol = case status
                 when 'good' then '✓'
                 when 'warning' then '⚠'
                 when 'critical' then '✗'
                 else ' '
                 end
        puts "  #{symbol} #{status.to_s.capitalize.ljust(18)}: #{count}"
      end
      puts ""

      # Show key metrics
      puts "Key Metrics:"

      clash_resolution = Bim::PortfolioMetric.portfolio_wide.for_metric_type('clash').for_metric_name('resolution_rate').for_date(date).first
      if clash_resolution
        puts "  Clash Resolution Rate: #{clash_resolution.formatted_value} (#{clash_resolution.status})"
      end

      issue_closure = Bim::PortfolioMetric.portfolio_wide.for_metric_type('issue').for_metric_name('closure_rate').for_date(date).first
      if issue_closure
        puts "  Issue Closure Rate: #{issue_closure.formatted_value} (#{issue_closure.status})"
      end

      workflow_completion = Bim::PortfolioMetric.portfolio_wide.for_metric_type('workflow').for_metric_name('completion_rate').for_date(date).first
      if workflow_completion
        puts "  Workflow Completion: #{workflow_completion.formatted_value} (#{workflow_completion.status})"
      end

      progress_avg = Bim::PortfolioMetric.portfolio_wide.for_metric_type('progress').for_metric_name('avg_completion').for_date(date).first
      if progress_avg
        puts "  Average Completion: #{progress_avg.formatted_value} (#{progress_avg.status})"
      end

      model_conversion = Bim::PortfolioMetric.portfolio_wide.for_metric_type('model').for_metric_name('conversion_rate').for_date(date).first
      if model_conversion
        puts "  Model Conversion Rate: #{model_conversion.formatted_value} (#{model_conversion.status})"
      end

      puts "\n"
    end

    desc 'Compare projects by specific metric'
    task compare: :environment do
      metric_type = ENV['METRIC_TYPE']
      metric_name = ENV['METRIC_NAME']
      date = ENV['DATE'] ? Date.parse(ENV['DATE']) : Date.current

      raise 'METRIC_TYPE and METRIC_NAME required' unless metric_type && metric_name

      puts "\n=== Project Comparison: #{metric_type}/#{metric_name} (#{date}) ===\n"

      comparison = Bim::PortfolioMetric.project_comparison(
        metric_type,
        metric_name,
        date: date
      )

      if comparison.empty?
        puts "No data available for this metric"
      else
        # Sort by value descending
        sorted = comparison.sort_by { |c| -c[:value].to_f }

        sorted.each_with_index do |project_data, index|
          rank = index + 1
          puts "#{rank.to_s.rjust(3)}. #{project_data[:project_name].ljust(40)}: #{project_data[:formatted_value].ljust(15)} [#{project_data[:status]}] #{trend_symbol(project_data[:trend])}"
        end

        # Calculate statistics
        values = sorted.map { |c| c[:value].to_f }
        avg = (values.sum / values.size).round(2)
        max_val = values.max
        min_val = values.min

        puts "\nStatistics:"
        puts "  Average: #{avg}"
        puts "  Maximum: #{max_val}"
        puts "  Minimum: #{min_val}"
        puts "  Range: #{(max_val - min_val).round(2)}"
      end

      puts "\n"
    end

    desc 'Show time series for a specific metric'
    task time_series: :environment do
      metric_type = ENV['METRIC_TYPE']
      metric_name = ENV['METRIC_NAME']
      start_date = ENV['START_DATE'] ? Date.parse(ENV['START_DATE']) : 30.days.ago.to_date
      end_date = ENV['END_DATE'] ? Date.parse(ENV['END_DATE']) : Date.current
      scope = ENV['SCOPE'] || 'portfolio'
      project_id = ENV['PROJECT_ID']

      raise 'METRIC_TYPE and METRIC_NAME required' unless metric_type && metric_name

      puts "\n=== Time Series: #{metric_type}/#{metric_name} ===\n"
      puts "Scope: #{scope}"
      puts "Project: #{project_id || 'N/A'}" if scope == 'project'
      puts "Period: #{start_date} to #{end_date}\n\n"

      series = Bim::PortfolioMetric.time_series(
        metric_type,
        metric_name,
        scope: scope,
        project_id: project_id,
        start_date: start_date,
        end_date: end_date
      )

      if series.empty?
        puts "No data available for this period"
      else
        series.each do |point|
          trend_sym = trend_symbol(point[:trend])
          change = point[:change_percentage] ? "(#{point[:change_percentage] > 0 ? '+' : ''}#{point[:change_percentage].round(2)}%)" : ''
          puts "#{point[:date]} | #{point[:value].to_s.ljust(10)} #{trend_sym} #{change}"
        end

        puts "\nData points: #{series.size}"
      end

      puts "\n"
    end

    desc 'Export portfolio metrics to CSV or JSON'
    task export: :environment do
      format = ENV['FORMAT'] || 'csv'
      output_file = ENV['OUTPUT'] || "portfolio_metrics_#{Time.current.to_i}.#{format}"
      start_date = ENV['START_DATE'] ? Date.parse(ENV['START_DATE']) : 30.days.ago.to_date
      end_date = ENV['END_DATE'] ? Date.parse(ENV['END_DATE']) : Date.current

      metrics = Bim::PortfolioMetric.between(start_date, end_date).fresh
      metrics = metrics.for_scope(ENV['SCOPE']) if ENV['SCOPE']
      metrics = metrics.by_category(ENV['CATEGORY']) if ENV['CATEGORY']
      metrics = metrics.for_project(ENV['PROJECT_ID']) if ENV['PROJECT_ID']

      puts "Exporting #{metrics.count} metrics to #{output_file}..."

      case format
      when 'csv'
        require 'csv'
        CSV.open(output_file, 'w', headers: true) do |csv|
          csv << [
            'Date',
            'Type',
            'Name',
            'Scope',
            'Project',
            'Value',
            'Unit',
            'Category',
            'Status',
            'Trend',
            'Previous Value',
            'Change %',
            'Threshold Good',
            'Threshold Warning',
            'Collected At',
            'Collected By'
          ]

          metrics.each do |metric|
            csv << [
              metric.metric_date,
              metric.metric_type,
              metric.metric_name,
              metric.scope,
              metric.project&.name,
              metric.value,
              metric.unit,
              metric.category,
              metric.status,
              metric.trend,
              metric.previous_value,
              metric.change_percentage,
              metric.threshold_good,
              metric.threshold_warning,
              metric.collected_at,
              metric.collected_by&.name
            ]
          end
        end
      when 'json'
        data = metrics.map do |metric|
          {
            date: metric.metric_date,
            type: metric.metric_type,
            name: metric.metric_name,
            scope: metric.scope,
            project: metric.project&.name,
            value: metric.value.to_f,
            unit: metric.unit,
            category: metric.category,
            status: metric.status,
            trend: metric.trend,
            previous_value: metric.previous_value&.to_f,
            change_percentage: metric.change_percentage&.to_f,
            threshold_good: metric.threshold_good&.to_f,
            threshold_warning: metric.threshold_warning&.to_f,
            collected_at: metric.collected_at,
            collected_by: metric.collected_by&.name
          }
        end
        File.write(output_file, JSON.pretty_generate(data))
      else
        raise "Unsupported format: #{format}"
      end

      puts "✓ Exported to #{output_file}"
      puts "  File size: #{(File.size(output_file) / 1024.0).round(2)} KB"
    end

    desc 'Clean up stale metrics'
    task cleanup: :environment do
      older_than = ENV['OLDER_THAN'] ? Time.parse(ENV['OLDER_THAN']) : 90.days.ago

      puts "Marking metrics older than #{older_than.strftime('%Y-%m-%d')} as stale..."

      marked = Bim::PortfolioMetric.mark_stale!(older_than: older_than)

      puts "✓ Marked #{marked} metrics as stale"

      if ENV['DELETE'] == 'true'
        puts "\nDeleting stale metrics..."
        deleted = Bim::PortfolioMetric.stale.delete_all
        puts "✓ Deleted #{deleted} stale metrics"
      else
        puts "\nTo permanently delete stale metrics, run: rake bim:portfolio:cleanup DELETE=true"
      end

      puts "\n"
    end

    desc 'Show top and bottom performing projects'
    task rankings: :environment do
      metric_type = ENV['METRIC_TYPE']
      metric_name = ENV['METRIC_NAME']
      date = ENV['DATE'] ? Date.parse(ENV['DATE']) : Date.current
      limit = ENV['LIMIT']&.to_i || 5

      raise 'METRIC_TYPE and METRIC_NAME required' unless metric_type && metric_name

      puts "\n=== Project Rankings: #{metric_type}/#{metric_name} (#{date}) ===\n"

      top = Bim::PortfolioMetric.top_performers(metric_type, metric_name, date: date, limit: limit)
      bottom = Bim::PortfolioMetric.bottom_performers(metric_type, metric_name, date: date, limit: limit)

      puts "Top #{limit} Performers:"
      top.each_with_index do |metric, index|
        puts "  #{(index + 1).to_s.rjust(2)}. #{metric.project.name.ljust(40)}: #{metric.formatted_value}"
      end

      puts "\nBottom #{limit} Performers:"
      bottom.each_with_index do |metric, index|
        puts "  #{(index + 1).to_s.rjust(2)}. #{metric.project.name.ljust(40)}: #{metric.formatted_value}"
      end

      puts "\n"
    end

    desc 'Schedule the portfolio metrics collection job'
    task schedule: :environment do
      # This task is for documentation - actual scheduling should be done in your job scheduler
      # Examples:
      # - cron: 0 2 * * * cd /path/to/app && rake bim:portfolio:collect RAILS_ENV=production
      # - whenever gem: every 1.day, at: '2:00 am' { rake 'bim:portfolio:collect' }
      # - sidekiq-cron or similar

      puts "\n=== Portfolio Metrics Collection Scheduling ===\n"
      puts "To schedule automatic metrics collection, use one of these methods:\n\n"

      puts "1. Cron (add to crontab):"
      puts "   0 2 * * * cd #{Rails.root} && #{Gem.ruby} bin/rake bim:portfolio:collect RAILS_ENV=production\n\n"

      puts "2. Whenever gem (in schedule.rb):"
      puts "   every 1.day, at: '2:00 am' do"
      puts "     rake 'bim:portfolio:collect'"
      puts "   end\n\n"

      puts "3. Background job (in Rails console or initializer):"
      puts "   Bim::PortfolioMetricsCollectorJob.perform_later\n\n"

      puts "Recommended: Run daily at 2:00 AM to collect metrics for the current date"
      puts "\n"
    end

    private

    def trend_symbol(trend)
      case trend
      when 'improving' then '↑'
      when 'declining' then '↓'
      when 'stable' then '→'
      else ' '
      end
    end
  end
end
