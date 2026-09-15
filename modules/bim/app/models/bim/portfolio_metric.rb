# frozen_string_literal: true

module Bim
  class PortfolioMetric < ApplicationRecord
    self.table_name = 'bim_portfolio_metrics'

    # Associations
    belongs_to :project, optional: true
    belongs_to :collected_by, class_name: 'User', optional: true

    # Validations
    validates :metric_type, presence: true, length: { maximum: 50 }
    validates :metric_name, presence: true, length: { maximum: 100 }
    validates :metric_date, presence: true
    validates :scope, presence: true, inclusion: { in: %w[portfolio project discipline] }
    validates :value, presence: true
    validates :collected_at, presence: true
    validate :validate_project_scope_consistency

    # Scopes
    scope :for_project, ->(project_id) { where(project_id: project_id) }
    scope :for_metric_type, ->(type) { where(metric_type: type) }
    scope :for_metric_name, ->(name) { where(metric_name: name) }
    scope :for_scope, ->(scope) { where(scope: scope) }
    scope :for_category, ->(category) { where(category: category) }
    scope :for_discipline, ->(discipline) { where(discipline: discipline) }
    scope :portfolio_wide, -> { where(scope: 'portfolio') }
    scope :project_level, -> { where(scope: 'project') }
    scope :on_date, ->(date) { where(metric_date: date) }
    scope :in_date_range, ->(start_date, end_date) { where(metric_date: start_date..end_date) }
    scope :recent, ->(days = 30) { where('metric_date >= ?', days.days.ago.to_date) }
    scope :by_status, ->(status) { where(status: status) }
    scope :good_status, -> { where(status: 'good') }
    scope :warning_status, -> { where(status: 'warning') }
    scope :critical_status, -> { where(status: 'critical') }
    scope :improving, -> { where(trend: 'improving') }
    scope :declining, -> { where(trend: 'declining') }
    scope :stable, -> { where(trend: 'stable') }
    scope :fresh, -> { where(stale: false) }
    scope :stale_metrics, -> { where(stale: true) }
    scope :tagged_with, ->(tag) { where('? = ANY(tags)', tag) }
    scope :latest, -> { order(metric_date: :desc, collected_at: :desc) }
    scope :chronological, -> { order(metric_date: :asc) }

    # Class methods

    # Get latest metrics for dashboard
    def self.dashboard_summary(scope: 'portfolio', project_id: nil, date: nil)
      metrics = scope == 'portfolio' ? portfolio_wide : for_project(project_id)
      metrics = metrics.on_date(date || Date.current)
      metrics = metrics.fresh

      {
        total_metrics: metrics.count,
        by_category: metrics.group(:category).count,
        by_status: metrics.group(:status).count,
        by_trend: metrics.group(:trend).count,
        critical_count: metrics.critical_status.count,
        warning_count: metrics.warning_status.count,
        improving_count: metrics.improving.count,
        declining_count: metrics.declining.count
      }
    end

    # Get time series data for a metric
    def self.time_series(metric_type, metric_name, start_date: 30.days.ago.to_date, end_date: Date.current, scope: 'portfolio', project_id: nil)
      metrics = for_metric_type(metric_type).for_metric_name(metric_name)
      metrics = metrics.in_date_range(start_date, end_date)
      metrics = scope == 'portfolio' ? metrics.portfolio_wide : metrics.for_project(project_id)

      metrics.chronological.map do |m|
        {
          date: m.metric_date,
          value: m.value.to_f,
          trend: m.trend,
          status: m.status,
          change_percentage: m.change_percentage&.to_f
        }
      end
    end

    # Get comparative metrics across projects
    def self.project_comparison(metric_type, metric_name, date: Date.current)
      for_metric_type(metric_type)
        .for_metric_name(metric_name)
        .project_level
        .on_date(date)
        .fresh
        .includes(:project)
        .map do |m|
          {
            project_id: m.project_id,
            project_name: m.project.name,
            value: m.value.to_f,
            status: m.status,
            trend: m.trend,
            details: m.details
          }
        end
    end

    # Get top/bottom performers
    def self.ranking(metric_type, metric_name, date: Date.current, order: :desc, limit: 10)
      metrics = for_metric_type(metric_type)
                .for_metric_name(metric_name)
                .project_level
                .on_date(date)
                .fresh
                .includes(:project)

      metrics = order == :desc ? metrics.order(value: :desc) : metrics.order(value: :asc)

      metrics.limit(limit).map do |m|
        {
          project_id: m.project_id,
          project_name: m.project.name,
          value: m.value.to_f,
          rank: nil # Will be filled in by caller
        }
      end.each_with_index.map { |item, index| item.merge(rank: index + 1) }
    end

    # Get metrics by category for pie charts
    def self.category_breakdown(date: Date.current, scope: 'portfolio', project_id: nil)
      metrics = scope == 'portfolio' ? portfolio_wide : for_project(project_id)
      metrics = metrics.on_date(date).fresh

      metrics.group(:category).average(:value).transform_values(&:to_f)
    end

    # Mark old metrics as stale
    def self.mark_stale!(older_than: 2.days.ago)
      where('collected_at < ?', older_than)
        .where(stale: false)
        .update_all(stale: true)
    end

    # Instance methods

    # Calculate status based on thresholds
    def calculate_status
      return nil unless value && threshold_good && threshold_warning

      if value >= threshold_good
        'good'
      elsif value >= threshold_warning
        'warning'
      else
        'critical'
      end
    end

    # Calculate trend based on previous value
    def calculate_trend
      return 'stable' unless previous_value && value

      change_pct = ((value - previous_value) / previous_value * 100).round(2)

      if change_pct.abs < 5
        'stable'
      elsif change_pct > 0
        'improving'
      else
        'declining'
      end
    end

    # Calculate change metrics
    def calculate_change
      return unless previous_value

      self.change_amount = value - previous_value
      self.change_percentage = ((change_amount / previous_value) * 100).round(2)
    end

    # Update all calculated fields
    def update_calculated_fields!
      calculate_change
      self.trend = calculate_trend
      self.status = calculate_status
      save!
    end

    # Get formatted value with unit
    def formatted_value
      case unit
      when 'percentage'
        "#{value.round(1)}%"
      when 'count'
        value.to_i.to_s
      when 'days'
        "#{value.round(1)} days"
      when 'hours'
        "#{value.round(1)} hours"
      else
        value.to_s
      end
    end

    # Get change indicator
    def change_indicator
      return '+0%' unless change_percentage

      sign = change_percentage >= 0 ? '+' : ''
      "#{sign}#{change_percentage.round(1)}%"
    end

    # Check if metric is healthy
    def healthy?
      status == 'good'
    end

    # Check if metric needs attention
    def needs_attention?
      status == 'warning' || status == 'critical'
    end

    # Export to hash
    def to_hash
      {
        id: id,
        metric_type: metric_type,
        metric_name: metric_name,
        metric_date: metric_date.iso8601,
        scope: scope,
        project_id: project_id,
        project_name: project&.name,
        value: value.to_f,
        formatted_value: formatted_value,
        unit: unit,
        category: category,
        discipline: discipline,
        tags: tags,
        previous_value: previous_value&.to_f,
        change_amount: change_amount&.to_f,
        change_percentage: change_percentage&.to_f,
        change_indicator: change_indicator,
        trend: trend,
        status: status,
        healthy: healthy?,
        details: details,
        breakdown: breakdown,
        sample_count: sample_count,
        collected_at: collected_at.iso8601,
        stale: stale
      }
    end

    private

    def validate_project_scope_consistency
      if scope == 'project' && project_id.nil?
        errors.add(:project_id, "must be present when scope is 'project'")
      end

      if scope == 'portfolio' && project_id.present?
        errors.add(:project_id, "must be nil when scope is 'portfolio'")
      end
    end
  end
end
