# frozen_string_literal: true

module Bim
  module Services
    # Statistical Analysis Service for Portfolio Metrics
    # Provides advanced statistical calculations, anomaly detection, and trend analysis
    class StatisticalAnalysisService
      attr_reader :metric_type, :metric_name, :project_id, :scope

      def initialize(metric_type:, metric_name:, project_id: nil, scope: 'portfolio')
        @metric_type = metric_type
        @metric_name = metric_name
        @project_id = project_id
        @scope = scope
      end

      # Calculate comprehensive statistics for a dataset
      def calculate_statistics(values, options = {})
        return {} if values.empty?

        values = values.compact.map(&:to_f)
        n = values.size

        stats = {
          sample_size: n,
          mean_value: mean(values),
          median_value: median(values),
          min_value: values.min,
          max_value: values.max,
          variance: variance(values),
          std_dev: standard_deviation(values)
        }

        # Calculate percentiles
        stats[:percentile_25] = percentile(values, 25)
        stats[:percentile_75] = percentile(values, 75)
        stats[:percentile_90] = percentile(values, 90)

        # Calculate confidence interval if requested
        if options[:confidence_level]
          ci = confidence_interval(values, options[:confidence_level])
          stats[:confidence_interval_lower] = ci[:lower]
          stats[:confidence_interval_upper] = ci[:upper]
          stats[:confidence_level] = options[:confidence_level]
        end

        stats
      end

      # Analyze time series data
      def analyze_time_series(start_date:, end_date:, project_id: nil)
        metrics = fetch_metrics(start_date: start_date, end_date: end_date, project_id: project_id)

        return {} if metrics.empty?

        values = metrics.pluck(:value).compact.map(&:to_f)
        dates = metrics.pluck(:metric_date)

        analysis = {
          period: {
            start: start_date,
            end: end_date,
            days: (end_date - start_date).to_i
          },
          statistics: calculate_statistics(values),
          trend: calculate_trend(values, dates),
          moving_averages: {
            ma_7: moving_average(values, 7),
            ma_30: moving_average(values, 30),
            ma_90: moving_average(values, 90)
          },
          seasonality: detect_seasonality(values, dates),
          anomalies: detect_anomalies(values, dates)
        }

        analysis
      end

      # Compare against benchmark
      def compare_to_benchmark(value, project_type: nil, project_size: nil, region: nil)
        benchmark = Bim::IndustryBenchmark.find_benchmark(
          metric_type: @metric_type,
          metric_name: @metric_name,
          project_type: project_type,
          project_size: project_size,
          region: region
        )

        return {} unless benchmark

        {
          value: value,
          benchmark_mean: benchmark.mean_value,
          benchmark_median: benchmark.median_value,
          variance_from_benchmark: benchmark.variance_from_mean(value),
          percentile_rank: benchmark.percentile_rank_for(value),
          performance_category: benchmark.performance_category(value),
          benchmark_source: benchmark.source,
          sample_size: benchmark.sample_size
        }
      end

      # Detect anomalies in a time series
      def detect_anomalies_for_period(start_date:, end_date:, method: 'zscore', threshold: 3.0)
        metrics = fetch_metrics(start_date: start_date, end_date: end_date)

        return [] if metrics.empty?

        values = metrics.map { |m| [m.metric_date, m.value.to_f] }
        anomalies = []

        case method
        when 'zscore'
          anomalies = detect_anomalies_zscore(values, threshold)
        when 'iqr'
          anomalies = detect_anomalies_iqr(values)
        when 'isolation_forest'
          anomalies = detect_anomalies_isolation_forest(values)
        end

        anomalies
      end

      # Calculate forecast using simple methods
      def forecast(horizon_days: 7, method: 'exponential_smoothing')
        # Get historical data (last 90 days)
        end_date = Date.current
        start_date = end_date - 90.days

        metrics = fetch_metrics(start_date: start_date, end_date: end_date)
        return {} if metrics.size < 7

        values = metrics.pluck(:value).compact.map(&:to_f)

        case method
        when 'moving_average'
          forecast_value = moving_average(values, 7)&.last
        when 'exponential_smoothing'
          forecast_value = exponential_smoothing(values, alpha: 0.3)
        when 'linear_regression'
          forecast_value = linear_regression_forecast(values, horizon_days)
        else
          forecast_value = values.last
        end

        {
          method: method,
          forecast_date: end_date + horizon_days.days,
          forecast_value: forecast_value,
          confidence_interval: forecast_confidence_interval(values, forecast_value),
          based_on_days: values.size
        }
      end

      private

      # Fetch metrics from database
      def fetch_metrics(start_date:, end_date:, project_id: nil)
        metrics = Bim::PortfolioMetric
                  .for_metric_type(@metric_type)
                  .for_metric_name(@metric_name)
                  .between(start_date, end_date)
                  .fresh
                  .order(:metric_date)

        metrics = metrics.for_project(project_id) if project_id
        metrics = metrics.for_scope(@scope) if @scope

        metrics
      end

      # Statistical calculation methods

      def mean(values)
        return nil if values.empty?

        values.sum / values.size.to_f
      end

      def median(values)
        return nil if values.empty?

        sorted = values.sort
        mid = sorted.size / 2

        if sorted.size.odd?
          sorted[mid]
        else
          (sorted[mid - 1] + sorted[mid]) / 2.0
        end
      end

      def variance(values)
        return nil if values.size < 2

        avg = mean(values)
        values.map { |v| (v - avg)**2 }.sum / (values.size - 1).to_f
      end

      def standard_deviation(values)
        return nil if values.size < 2

        Math.sqrt(variance(values))
      end

      def percentile(values, p)
        return nil if values.empty?

        sorted = values.sort
        index = (p / 100.0) * (sorted.size - 1)
        lower = sorted[index.floor]
        upper = sorted[index.ceil]

        lower + (upper - lower) * (index - index.floor)
      end

      def confidence_interval(values, confidence_level = 95.0)
        return {} if values.size < 2

        avg = mean(values)
        std = standard_deviation(values)
        n = values.size

        # Use t-distribution for small samples
        t_value = if n >= 30
                    # Normal distribution approximation for large samples
                    case confidence_level
                    when 90.0 then 1.645
                    when 95.0 then 1.96
                    when 99.0 then 2.576
                    else 1.96
                    end
                  else
                    # t-distribution for small samples (simplified)
                    case confidence_level
                    when 90.0 then 1.833
                    when 95.0 then 2.262
                    when 99.0 then 3.250
                    else 2.262
                    end
                  end

        margin_of_error = t_value * (std / Math.sqrt(n))

        {
          lower: avg - margin_of_error,
          upper: avg + margin_of_error,
          confidence_level: confidence_level
        }
      end

      # Trend analysis

      def calculate_trend(values, dates)
        return {} if values.size < 2

        # Calculate linear regression
        x_values = (0...values.size).to_a
        slope, intercept = simple_linear_regression(x_values, values)

        # Determine trend direction
        trend_direction = if slope.abs < 0.01
                            'stable'
                          elsif slope > 0
                            'improving'
                          else
                            'declining'
                          end

        {
          direction: trend_direction,
          slope: slope,
          intercept: intercept,
          correlation: correlation_coefficient(x_values, values)
        }
      end

      def simple_linear_regression(x_values, y_values)
        n = x_values.size
        sum_x = x_values.sum
        sum_y = y_values.sum
        sum_xy = x_values.zip(y_values).map { |x, y| x * y }.sum
        sum_x2 = x_values.map { |x| x**2 }.sum

        slope = (n * sum_xy - sum_x * sum_y).to_f / (n * sum_x2 - sum_x**2)
        intercept = (sum_y - slope * sum_x) / n.to_f

        [slope, intercept]
      end

      def correlation_coefficient(x_values, y_values)
        n = x_values.size
        mean_x = mean(x_values)
        mean_y = mean(y_values)

        numerator = x_values.zip(y_values).map { |x, y| (x - mean_x) * (y - mean_y) }.sum
        denominator_x = Math.sqrt(x_values.map { |x| (x - mean_x)**2 }.sum)
        denominator_y = Math.sqrt(y_values.map { |y| (y - mean_y)**2 }.sum)

        numerator / (denominator_x * denominator_y)
      end

      # Moving averages

      def moving_average(values, window_size)
        return [] if values.size < window_size

        (0..(values.size - window_size)).map do |i|
          values[i, window_size].sum / window_size.to_f
        end
      end

      def exponential_smoothing(values, alpha: 0.3)
        return nil if values.empty?

        smoothed = values.first

        values[1..].each do |value|
          smoothed = alpha * value + (1 - alpha) * smoothed
        end

        smoothed
      end

      # Seasonality detection

      def detect_seasonality(values, dates)
        return {} if values.size < 30

        # Simple seasonality detection using autocorrelation
        # Check for weekly (7-day) and monthly (30-day) patterns

        weekly_correlation = autocorrelation(values, lag: 7)
        monthly_correlation = autocorrelation(values, lag: 30)

        seasonality_detected = weekly_correlation > 0.5 || monthly_correlation > 0.5

        {
          detected: seasonality_detected,
          weekly_correlation: weekly_correlation,
          monthly_correlation: monthly_correlation
        }
      end

      def autocorrelation(values, lag:)
        return 0 if values.size < lag + 1

        n = values.size - lag
        mean_val = mean(values)

        numerator = (0...n).map { |i| (values[i] - mean_val) * (values[i + lag] - mean_val) }.sum
        denominator = values.map { |v| (v - mean_val)**2 }.sum

        numerator / denominator
      end

      # Anomaly detection

      def detect_anomalies(values, dates)
        return [] if values.size < 7

        anomalies = []
        avg = mean(values)
        std = standard_deviation(values)

        threshold = 3.0  # 3 standard deviations

        values.each_with_index do |value, index|
          z_score = (value - avg) / std

          if z_score.abs > threshold
            anomalies << {
              date: dates[index],
              value: value,
              z_score: z_score,
              type: z_score > 0 ? 'spike' : 'drop'
            }
          end
        end

        anomalies
      end

      def detect_anomalies_zscore(values, threshold = 3.0)
        return [] if values.empty?

        data_values = values.map { |_, v| v }
        avg = mean(data_values)
        std = standard_deviation(data_values)

        anomalies = []

        values.each do |date, value|
          z_score = (value - avg) / std

          if z_score.abs > threshold
            anomalies << {
              date: date,
              value: value,
              z_score: z_score,
              anomaly_type: z_score > 0 ? 'spike' : 'drop',
              threshold: threshold
            }
          end
        end

        anomalies
      end

      def detect_anomalies_iqr(values)
        return [] if values.empty?

        data_values = values.map { |_, v| v }
        q1 = percentile(data_values, 25)
        q3 = percentile(data_values, 75)
        iqr = q3 - q1

        lower_bound = q1 - 1.5 * iqr
        upper_bound = q3 + 1.5 * iqr

        anomalies = []

        values.each do |date, value|
          if value < lower_bound || value > upper_bound
            anomalies << {
              date: date,
              value: value,
              lower_bound: lower_bound,
              upper_bound: upper_bound,
              anomaly_type: value < lower_bound ? 'drop' : 'spike'
            }
          end
        end

        anomalies
      end

      def detect_anomalies_isolation_forest(values)
        # Simplified isolation forest implementation
        # In production, use a proper ML library
        detect_anomalies_iqr(values)  # Fallback to IQR method
      end

      # Forecasting helpers

      def linear_regression_forecast(values, horizon_days)
        x_values = (0...values.size).to_a
        slope, intercept = simple_linear_regression(x_values, values)

        # Forecast for horizon days ahead
        future_x = values.size + horizon_days - 1
        slope * future_x + intercept
      end

      def forecast_confidence_interval(values, forecast_value)
        std = standard_deviation(values)
        margin = 1.96 * std  # 95% confidence

        {
          lower: forecast_value - margin,
          upper: forecast_value + margin,
          confidence_level: 95.0
        }
      end
    end
  end
end
