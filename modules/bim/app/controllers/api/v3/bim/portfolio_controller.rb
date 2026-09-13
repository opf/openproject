# frozen_string_literal: true

module API
  module V3
    module Bim
      class PortfolioController < ApplicationController
        before_action :authorize_portfolio_access
        before_action :set_date_filter, only: [:dashboard, :metrics, :time_series]
        before_action :set_projects_filter, only: [:dashboard, :metrics, :comparison]

        # GET /api/v3/bim/portfolio/dashboard
        # Returns high-level portfolio summary with key metrics
        def dashboard
          analytics = ::Bim::Services::PortfolioAnalyticsService.new(
            date: @date,
            projects: @projects
          )

          summary = ::Bim::PortfolioMetric.dashboard_summary(
            scope: 'portfolio',
            date: @date
          )

          # Get latest metrics by category
          latest_metrics = ::Bim::PortfolioMetric.portfolio_wide
                                                  .fresh
                                                  .for_date(@date)
                                                  .group_by(&:category)

          render json: {
            _type: 'PortfolioDashboard',
            date: @date.iso8601,
            generated_at: Time.current.iso8601,
            summary: summary,
            metrics: {
              quality: metrics_by_category(latest_metrics['quality']),
              performance: metrics_by_category(latest_metrics['performance']),
              collaboration: metrics_by_category(latest_metrics['collaboration']),
              progress: metrics_by_category(latest_metrics['progress'])
            },
            status_overview: {
              good: ::Bim::PortfolioMetric.portfolio_wide.good_status.count,
              warning: ::Bim::PortfolioMetric.portfolio_wide.warning_status.count,
              critical: ::Bim::PortfolioMetric.portfolio_wide.critical_status.count
            },
            trends: {
              improving: ::Bim::PortfolioMetric.portfolio_wide.improving.count,
              declining: ::Bim::PortfolioMetric.portfolio_wide.declining.count,
              stable: ::Bim::PortfolioMetric.portfolio_wide.stable.count
            },
            project_count: @projects.count,
            _links: {
              self: { href: api_v3_bim_portfolio_dashboard_path },
              metrics: { href: api_v3_bim_portfolio_metrics_path },
              comparison: { href: api_v3_bim_portfolio_comparison_path }
            }
          }
        end

        # GET /api/v3/bim/portfolio/metrics
        # Returns detailed metrics with filtering
        def metrics
          metrics = ::Bim::PortfolioMetric.all

          # Apply filters
          metrics = metrics.for_scope(params[:scope]) if params[:scope]
          metrics = metrics.for_metric_type(params[:metric_type]) if params[:metric_type]
          metrics = metrics.for_metric_name(params[:metric_name]) if params[:metric_name]
          metrics = metrics.by_category(params[:category]) if params[:category]
          metrics = metrics.by_status(params[:status]) if params[:status]
          metrics = metrics.for_project(params[:project_id]) if params[:project_id]

          # Apply date range
          if params[:start_date]
            metrics = metrics.between(Date.parse(params[:start_date]), @date)
          else
            metrics = metrics.for_date(@date)
          end

          # Exclude stale metrics
          metrics = metrics.fresh unless params[:include_stale] == 'true'

          # Pagination
          page = (params[:page] || 1).to_i
          per_page = [(params[:per_page] || 50).to_i, 200].min
          total = metrics.count
          metrics = metrics.limit(per_page).offset((page - 1) * per_page)

          render json: {
            _type: 'PortfolioMetricsCollection',
            total: total,
            count: metrics.size,
            page: page,
            per_page: per_page,
            _embedded: {
              metrics: metrics.map { |m| metric_representer(m) }
            },
            _links: {
              self: { href: request.original_url }
            }
          }
        end

        # GET /api/v3/bim/portfolio/time_series
        # Returns time series data for trending charts
        def time_series
          metric_type = params[:metric_type]
          metric_name = params[:metric_name]
          start_date = params[:start_date] ? Date.parse(params[:start_date]) : 30.days.ago.to_date
          end_date = @date

          unless metric_type && metric_name
            return render json: { error: 'metric_type and metric_name required' }, status: :bad_request
          end

          scope = params[:scope] || 'portfolio'
          project_id = params[:project_id]

          series_data = ::Bim::PortfolioMetric.time_series(
            metric_type,
            metric_name,
            scope: scope,
            project_id: project_id,
            start_date: start_date,
            end_date: end_date
          )

          render json: {
            _type: 'PortfolioTimeSeries',
            metric_type: metric_type,
            metric_name: metric_name,
            scope: scope,
            project_id: project_id,
            start_date: start_date.iso8601,
            end_date: end_date.iso8601,
            data_points: series_data.size,
            series: series_data,
            _links: {
              self: { href: request.original_url }
            }
          }
        end

        # GET /api/v3/bim/portfolio/comparison
        # Compare metrics across projects
        def comparison
          metric_type = params[:metric_type]
          metric_name = params[:metric_name]

          unless metric_type && metric_name
            return render json: { error: 'metric_type and metric_name required' }, status: :bad_request
          end

          comparison_data = ::Bim::PortfolioMetric.project_comparison(
            metric_type,
            metric_name,
            date: @date,
            projects: @projects
          )

          # Get rankings
          top_performers = ::Bim::PortfolioMetric.top_performers(
            metric_type,
            metric_name,
            date: @date,
            limit: params[:top_limit]&.to_i || 5
          )

          bottom_performers = ::Bim::PortfolioMetric.bottom_performers(
            metric_type,
            metric_name,
            date: @date,
            limit: params[:bottom_limit]&.to_i || 5
          )

          render json: {
            _type: 'PortfolioComparison',
            metric_type: metric_type,
            metric_name: metric_name,
            date: @date.iso8601,
            projects_compared: comparison_data.size,
            comparison: comparison_data,
            rankings: {
              top_performers: top_performers.map { |m| project_metric_summary(m) },
              bottom_performers: bottom_performers.map { |m| project_metric_summary(m) }
            },
            _links: {
              self: { href: request.original_url }
            }
          }
        end

        # GET /api/v3/bim/portfolio/breakdown
        # Get category breakdown for a specific date
        def breakdown
          category = params[:category]

          unless category
            return render json: { error: 'category parameter required' }, status: :bad_request
          end

          breakdown_data = ::Bim::PortfolioMetric.category_breakdown(
            category,
            scope: params[:scope] || 'portfolio',
            project_id: params[:project_id],
            date: @date
          )

          render json: {
            _type: 'PortfolioBreakdown',
            category: category,
            scope: params[:scope] || 'portfolio',
            date: @date.iso8601,
            breakdown: breakdown_data,
            _links: {
              self: { href: request.original_url }
            }
          }
        end

        # POST /api/v3/bim/portfolio/collect
        # Manually trigger metric collection
        def collect
          unless current_user.admin?
            return render json: { error: 'Admin access required' }, status: :forbidden
          end

          date = params[:date] ? Date.parse(params[:date]) : Date.current
          projects = params[:project_ids] ? Project.where(id: params[:project_ids]) : Project.where(active: true)

          analytics = ::Bim::Services::PortfolioAnalyticsService.new(
            date: date,
            projects: projects
          )

          results = analytics.collect_all_metrics(user: current_user)

          # Log the manual collection
          ::Bim::AuditLog.log(
            user: current_user,
            action: :portfolio_metrics_collected,
            details: {
              date: date,
              projects_processed: results[:projects_processed],
              metrics_collected: results[:metrics_collected],
              errors: results[:errors]
            },
            severity: :low,
            tags: ['portfolio', 'metrics', 'manual_collection']
          )

          render json: {
            _type: 'PortfolioCollectionResult',
            date: date.iso8601,
            collected_at: results[:collected_at].iso8601,
            projects_processed: results[:projects_processed],
            metrics_collected: results[:metrics_collected],
            errors: results[:errors],
            status: results[:errors].empty? ? 'success' : 'completed_with_errors'
          }
        end

        # GET /api/v3/bim/portfolio/export
        # Export portfolio data
        def export
          unless current_user.admin? || current_user.allowed_in_project?(:manage_ifc_models, @projects.first)
            return render json: { error: 'Export permission required' }, status: :forbidden
          end

          format = params[:format] || 'csv'
          start_date = params[:start_date] ? Date.parse(params[:start_date]) : 30.days.ago.to_date
          end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.current

          metrics = ::Bim::PortfolioMetric.between(start_date, end_date).fresh
          metrics = metrics.for_scope(params[:scope]) if params[:scope]
          metrics = metrics.by_category(params[:category]) if params[:category]

          case format
          when 'csv'
            csv_data = generate_csv(metrics)
            send_data csv_data,
                      filename: "portfolio_metrics_#{start_date}_#{end_date}.csv",
                      type: 'text/csv'
          when 'json'
            json_data = metrics.map { |m| metric_representer(m) }.to_json
            send_data json_data,
                      filename: "portfolio_metrics_#{start_date}_#{end_date}.json",
                      type: 'application/json'
          else
            render json: { error: "Invalid format: #{format}" }, status: :bad_request
          end

          # Log the export
          ::Bim::AuditLog.log(
            user: current_user,
            action: :export_data,
            details: {
              export_type: 'portfolio_metrics',
              format: format,
              record_count: metrics.count,
              date_range: { start: start_date, end: end_date }
            },
            severity: :medium,
            tags: ['portfolio', 'export', 'compliance']
          )
        end

        # GET /api/v3/bim/portfolio/stats
        # Get portfolio statistics
        def stats
          total_metrics = ::Bim::PortfolioMetric.count
          fresh_metrics = ::Bim::PortfolioMetric.fresh.count
          stale_metrics = ::Bim::PortfolioMetric.stale.count

          render json: {
            _type: 'PortfolioStatistics',
            total_metrics: total_metrics,
            fresh_metrics: fresh_metrics,
            stale_metrics: stale_metrics,
            by_scope: ::Bim::PortfolioMetric.group(:scope).count,
            by_category: ::Bim::PortfolioMetric.group(:category).count,
            by_status: ::Bim::PortfolioMetric.group(:status).count,
            by_trend: ::Bim::PortfolioMetric.fresh.group(:trend).count,
            latest_collection: ::Bim::PortfolioMetric.order(collected_at: :desc).first&.collected_at&.iso8601,
            oldest_metric: ::Bim::PortfolioMetric.order(metric_date: :asc).first&.metric_date&.iso8601,
            newest_metric: ::Bim::PortfolioMetric.order(metric_date: :desc).first&.metric_date&.iso8601
          }
        end

        private

        def authorize_portfolio_access
          unless current_user.admin? || current_user.allowed_in_any_project?(:view_ifc_models)
            render json: { error: 'Unauthorized - Portfolio access requires BIM permissions' }, status: :forbidden
          end
        end

        def set_date_filter
          @date = params[:date] ? Date.parse(params[:date]) : Date.current
        rescue ArgumentError
          render json: { error: 'Invalid date format' }, status: :bad_request
        end

        def set_projects_filter
          if params[:project_ids]
            @projects = Project.where(id: params[:project_ids].split(','))
          else
            @projects = Project.where(active: true)
          end
        end

        def metrics_by_category(metrics)
          return [] unless metrics

          metrics.map { |m| metric_summary(m) }
        end

        def metric_summary(metric)
          {
            type: metric.metric_type,
            name: metric.metric_name,
            value: metric.value.to_f,
            formatted_value: metric.formatted_value,
            unit: metric.unit,
            status: metric.status,
            trend: metric.trend,
            change_percentage: metric.change_percentage&.to_f
          }
        end

        def metric_representer(metric)
          {
            _type: 'PortfolioMetric',
            id: metric.id,
            metric_type: metric.metric_type,
            metric_name: metric.metric_name,
            metric_date: metric.metric_date.iso8601,
            scope: metric.scope,
            project: metric.project ? { id: metric.project_id, name: metric.project.name } : nil,
            value: metric.value.to_f,
            formatted_value: metric.formatted_value,
            unit: metric.unit,
            category: metric.category,
            discipline: metric.discipline,
            status: metric.status,
            trend: metric.trend,
            change: {
              previous_value: metric.previous_value&.to_f,
              change_amount: metric.change_amount&.to_f,
              change_percentage: metric.change_percentage&.to_f
            },
            thresholds: {
              good: metric.threshold_good&.to_f,
              warning: metric.threshold_warning&.to_f
            },
            details: metric.details,
            breakdown: metric.breakdown,
            tags: metric.tags,
            collected_at: metric.collected_at&.iso8601,
            collected_by: metric.collected_by ? { id: metric.collected_by.id, name: metric.collected_by.name } : nil,
            stale: metric.stale,
            _links: {
              self: { href: "/api/v3/bim/portfolio/metrics/#{metric.id}" },
              project: metric.project ? { href: "/api/v3/projects/#{metric.project_id}" } : nil
            }
          }
        end

        def project_metric_summary(metric)
          {
            project_id: metric.project_id,
            project_name: metric.project.name,
            value: metric.value.to_f,
            formatted_value: metric.formatted_value,
            status: metric.status,
            trend: metric.trend,
            rank: nil  # Can be calculated by caller
          }
        end

        def generate_csv(metrics)
          require 'csv'

          CSV.generate(headers: true) do |csv|
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
        end
      end
    end
  end
end
