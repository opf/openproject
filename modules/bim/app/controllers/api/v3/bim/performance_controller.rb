# frozen_string_literal: true

module API
  module V3
    module Bim
      class PerformanceController < ApplicationController
        before_action :require_admin

        # GET /api/v3/bim/performance/cache_stats
        def cache_stats
          stats = ::Bim::IfcModels::ResultCacheService.cache_statistics

          render json: {
            _type: 'CacheStatistics',
            cache_entries: stats[:total],
            total_size_bytes: stats[:size],
            total_size_mb: stats[:size_mb],
            performance_metrics: {
              hits: stats[:stats][:hits],
              misses: stats[:stats][:misses],
              stores: stats[:stats][:stores],
              evictions: stats[:stats][:evictions],
              hit_rate: stats[:stats][:hit_rate]
            },
            _links: {
              self: { href: api_v3_paths.bim_performance_cache_stats },
              cleanup: { href: api_v3_paths.bim_performance_cache_cleanup, method: :post }
            }
          }
        end

        # POST /api/v3/bim/performance/cache_cleanup
        def cache_cleanup
          cleaned_count = ::Bim::IfcModels::ResultCacheService.cleanup_expired

          render json: {
            _type: 'CacheCleanupResult',
            cleaned_entries: cleaned_count,
            message: "Successfully cleaned up #{cleaned_count} expired cache entries"
          }
        end

        # GET /api/v3/bim/performance/conversion_metrics
        def conversion_metrics
          # Get recent conversions with performance data
          recent_conversions = ::Bim::IfcModels::IfcModel
            .where(conversion_status: :completed)
            .where('updated_at > ?', 30.days.ago)
            .order(updated_at: :desc)
            .limit(100)

          metrics = calculate_conversion_metrics(recent_conversions)

          render json: {
            _type: 'ConversionMetrics',
            period: '30 days',
            total_conversions: metrics[:total],
            average_duration_seconds: metrics[:avg_duration],
            average_file_size_mb: metrics[:avg_file_size],
            average_throughput_mb_per_sec: metrics[:avg_throughput],
            fastest_conversion_seconds: metrics[:fastest],
            slowest_conversion_seconds: metrics[:slowest],
            _links: {
              self: { href: api_v3_paths.bim_performance_conversion_metrics }
            }
          }
        end

        # GET /api/v3/bim/performance/model/:id/logs
        def conversion_logs
          model = ::Bim::IfcModels::IfcModel.find(params[:id])

          authorize_model_access(model)

          logs = model.conversion_logs || []

          render json: {
            _type: 'ConversionLogs',
            model_id: model.id,
            model_title: model.title,
            conversion_status: model.conversion_status,
            total_logs: logs.count,
            logs: logs.map { |log| format_log_entry(log) },
            _links: {
              self: { href: api_v3_paths.bim_performance_conversion_logs(model.id) },
              model: { href: api_v3_paths.bim_ifc_model(model.id) }
            }
          }
        end

        private

        def require_admin
          render_403 unless current_user.admin?
        end

        def authorize_model_access(model)
          allowed = current_user.admin? ||
                    current_user.allowed_in_project?(:view_ifc_models, model.project)

          render_403 unless allowed
        end

        def calculate_conversion_metrics(conversions)
          return default_metrics if conversions.empty?

          durations = []
          file_sizes = []
          throughputs = []

          conversions.each do |model|
            next unless model.conversion_logs.present?

            # Extract performance data from logs
            perf_log = model.conversion_logs.find { |l| l['stage'] == 'performance' }
            next unless perf_log && perf_log['details']

            duration = perf_log['details']['duration_seconds']
            file_size = perf_log['details']['file_size_mb']
            throughput = perf_log['details']['throughput_mb_per_sec']

            durations << duration if duration
            file_sizes << file_size if file_size
            throughputs << throughput if throughput
          end

          {
            total: conversions.count,
            avg_duration: durations.empty? ? nil : (durations.sum / durations.count).round(2),
            avg_file_size: file_sizes.empty? ? nil : (file_sizes.sum / file_sizes.count).round(2),
            avg_throughput: throughputs.empty? ? nil : (throughputs.sum / throughputs.count).round(2),
            fastest: durations.empty? ? nil : durations.min.round(2),
            slowest: durations.empty? ? nil : durations.max.round(2)
          }
        end

        def default_metrics
          {
            total: 0,
            avg_duration: nil,
            avg_file_size: nil,
            avg_throughput: nil,
            fastest: nil,
            slowest: nil
          }
        end

        def format_log_entry(log)
          {
            timestamp: log['timestamp'],
            stage: log['stage'],
            level: log['level'],
            message: log['message'],
            details: log['details'] || {}
          }
        end

        def render_403
          render json: { error: 'Forbidden' }, status: :forbidden
        end
      end
    end
  end
end
