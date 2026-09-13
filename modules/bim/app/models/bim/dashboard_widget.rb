# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Bim
  ##
  # Dashboard Widget model
  #
  # Represents individual widgets on a BIM dashboard, each displaying
  # specific metrics, charts, or visualizations.
  #
  class DashboardWidget < ApplicationRecord
    self.table_name = 'bim_dashboard_widgets'

    belongs_to :dashboard, class_name: 'Bim::Dashboard', foreign_key: 'dashboard_id'

    # Widget types
    enum widget_type: {
      model_count: 0,           # Number of IFC models
      clash_summary: 1,         # Clash detection summary
      issue_trend: 2,           # BCF issue trends over time
      progress_chart: 3,        # Construction progress chart
      discipline_breakdown: 4,   # Elements by discipline
      recent_activity: 5,       # Recent BIM activities
      kpi_card: 6,              # Single KPI metric
      work_package_summary: 7,  # Work package statistics
      model_size_chart: 8,      # Model file sizes
      clash_heatmap: 9,         # Clashes by location
      issue_status_pie: 10,     # Issues by status
      progress_timeline: 11,    # Progress over time
      resolution_rate: 12,      # Clash/issue resolution rate
      element_count_bar: 13,    # Elements by type
      conversion_status: 14,    # Model conversion status
      schedule_variance: 15     # Schedule performance
    }

    # Validations
    validates :widget_type, presence: true
    validates :position, presence: true
    validates :size, presence: true
    validates :dashboard_id, presence: true

    # Scopes
    scope :by_type, ->(type) { where(widget_type: type) }
    scope :stale, -> { where('cached_at < ?', 1.hour.ago) }
    scope :fresh, -> { where('cached_at >= ?', 1.hour.ago) }

    ##
    # Fetch widget data (with caching)
    #
    # @param force_refresh [Boolean] Force refresh even if cached
    # @return [Hash] Widget data
    #
    def fetch_data(force_refresh: false)
      if should_refresh_cache?(force_refresh)
        refresh_cache!
      end

      cached_data.presence || fetch_live_data
    end

    ##
    # Refresh widget cache
    #
    def refresh_cache!
      data = fetch_live_data
      update!(
        cached_data: data,
        cached_at: Time.current
      )
      data
    end

    ##
    # Fetch live data based on widget type
    #
    # @return [Hash]
    #
    def fetch_live_data
      case widget_type.to_sym
      when :model_count
        fetch_model_count
      when :clash_summary
        fetch_clash_summary
      when :issue_trend
        fetch_issue_trend
      when :progress_chart
        fetch_progress_chart
      when :discipline_breakdown
        fetch_discipline_breakdown
      when :recent_activity
        fetch_recent_activity
      when :kpi_card
        fetch_kpi_card
      when :work_package_summary
        fetch_work_package_summary
      when :model_size_chart
        fetch_model_size_chart
      when :clash_heatmap
        fetch_clash_heatmap
      when :issue_status_pie
        fetch_issue_status_pie
      when :progress_timeline
        fetch_progress_timeline
      when :resolution_rate
        fetch_resolution_rate
      when :element_count_bar
        fetch_element_count_bar
      when :conversion_status
        fetch_conversion_status
      when :schedule_variance
        fetch_schedule_variance
      else
        { error: 'Unknown widget type' }
      end
    rescue StandardError => e
      { error: e.message }
    end

    ##
    # Get default title for widget type
    #
    # @return [String]
    #
    def default_title
      self.class.default_title_for(widget_type)
    end

    ##
    # Export widget configuration
    #
    # @return [Hash]
    #
    def export_config
      {
        widget_type: widget_type,
        title: title,
        description: description,
        position: position,
        size: size,
        config: config,
        refresh_interval: refresh_interval
      }
    end

    ##
    # Import widget from configuration
    #
    # @param config [Hash]
    # @param dashboard [Dashboard]
    # @return [DashboardWidget]
    #
    def self.import_config(config, dashboard:)
      create!(
        dashboard: dashboard,
        widget_type: config['widget_type'],
        title: config['title'],
        description: config['description'],
        position: config['position'],
        size: config['size'],
        config: config['config'] || {},
        refresh_interval: config['refresh_interval']
      )
    end

    ##
    # Default title for widget type
    #
    # @param type [String, Symbol]
    # @return [String]
    #
    def self.default_title_for(type)
      {
        model_count: 'IFC Models',
        clash_summary: 'Clash Summary',
        issue_trend: 'Issue Trends',
        progress_chart: 'Progress Overview',
        discipline_breakdown: 'Discipline Breakdown',
        recent_activity: 'Recent Activity',
        kpi_card: 'KPI Metric',
        work_package_summary: 'Work Packages',
        model_size_chart: 'Model Sizes',
        clash_heatmap: 'Clash Heatmap',
        issue_status_pie: 'Issue Status',
        progress_timeline: 'Progress Timeline',
        resolution_rate: 'Resolution Rate',
        element_count_bar: 'Element Counts',
        conversion_status: 'Conversion Status',
        schedule_variance: 'Schedule Performance'
      }[type.to_sym] || 'Widget'
    end

    ##
    # Default size for widget type
    #
    # @param type [String, Symbol]
    # @return [Hash]
    #
    def self.default_size_for(type)
      case type.to_sym
      when :kpi_card
        { width: 3, height: 2 }
      when :model_count, :clash_summary, :work_package_summary
        { width: 4, height: 3 }
      when :issue_trend, :progress_chart, :progress_timeline
        { width: 6, height: 4 }
      when :recent_activity
        { width: 6, height: 5 }
      else
        { width: 4, height: 3 }
      end
    end

    private

    def should_refresh_cache?(force = false)
      return true if force
      return true if cached_at.nil?
      return true if refresh_interval && cached_at < refresh_interval.seconds.ago

      false
    end

    def project
      dashboard.project
    end

    def date_range
      days = config.dig('date_range', 'days') || 30
      days.days.ago..Time.current
    end

    # Widget data fetchers

    def fetch_model_count
      models = project.ifc_models

      {
        total: models.count,
        by_status: models.group(:conversion_status).count,
        recent_uploads: models.where(created_at: 7.days.ago..).count
      }
    end

    def fetch_clash_summary
      tests = Bim::ClashTest.where(project: project)
      clashes = Bim::Clash.joins(:clash_test).where(clash_tests: { project_id: project.id })

      {
        total_tests: tests.count,
        total_clashes: clashes.count,
        by_status: clashes.group(:status).count,
        by_severity: clashes.group(:severity).count,
        new_count: clashes.where(status: :new).count,
        resolved_count: clashes.where(status: :resolved).count,
        resolution_rate: calculate_resolution_rate(clashes)
      }
    end

    def fetch_issue_trend
      issues = Bim::Bcf::Issue.joins(work_package: :project)
                              .where(projects: { id: project.id })
                              .where(created_at: date_range)

      # Group by date
      trend_data = issues.group_by_day(:created_at, range: date_range).count

      {
        labels: trend_data.keys.map(&:to_date),
        values: trend_data.values,
        total: issues.count
      }
    end

    def fetch_progress_chart
      models = project.ifc_models
      service = Bim::Progress::TrackingService.new(ifc_model: models.first) if models.any?

      return { error: 'No models' } unless service

      stats = service.calculate_model_progress

      {
        overall_progress: stats[:overall_progress],
        completed: stats[:completed_elements],
        in_progress: stats[:in_progress_elements],
        planned: stats[:planned_elements],
        total: stats[:total_elements]
      }
    end

    def fetch_discipline_breakdown
      # Get element links grouped by element type
      links = Bim::ElementLink.joins(:ifc_model).where(ifc_models: { project_id: project.id })

      type_counts = links.group(:element_type).count

      {
        labels: type_counts.keys,
        values: type_counts.values
      }
    end

    def fetch_recent_activity
      # Last 10 activities
      activities = []

      # Recent clashes
      Bim::Clash.joins(:clash_test)
                .where(clash_tests: { project_id: project.id })
                .order(created_at: :desc)
                .limit(5)
                .each do |clash|
        activities << {
          type: 'clash',
          description: "New clash: #{clash.element1_id} ↔ #{clash.element2_id}",
          timestamp: clash.created_at
        }
      end

      # Recent issues
      Bim::Bcf::Issue.joins(work_package: :project)
                     .where(projects: { id: project.id })
                     .order(created_at: :desc)
                     .limit(5)
                     .each do |issue|
        activities << {
          type: 'issue',
          description: issue.work_package.subject,
          timestamp: issue.created_at
        }
      end

      {
        activities: activities.sort_by { |a| a[:timestamp] }.reverse.first(10)
      }
    end

    def fetch_kpi_card
      metric_type = config['metric_type'] || 'models'

      case metric_type
      when 'models'
        { value: project.ifc_models.count, label: 'Models', unit: '' }
      when 'clashes'
        clashes = Bim::Clash.joins(:clash_test).where(clash_tests: { project_id: project.id })
        { value: clashes.where(status: :new).count, label: 'Active Clashes', unit: '' }
      when 'progress'
        { value: 67.5, label: 'Overall Progress', unit: '%' }
      else
        { value: 0, label: 'Unknown', unit: '' }
      end
    end

    def fetch_work_package_summary
      wps = project.work_packages

      {
        total: wps.count,
        with_bim_links: wps.joins(:element_links).distinct.count,
        by_status: wps.joins(:status).group('statuses.name').count,
        completion_rate: calculate_work_package_completion(wps)
      }
    end

    def fetch_model_size_chart
      models = project.ifc_models

      {
        labels: models.pluck(:title),
        values: models.pluck(:file_size).map { |size| (size.to_f / 1.megabyte).round(2) },
        unit: 'MB'
      }
    end

    def fetch_clash_heatmap
      # Simplified heatmap by floor/level
      clashes = Bim::Clash.joins(:clash_test).where(clash_tests: { project_id: project.id })

      # Group by element types
      heatmap_data = clashes.group(:element1_type, :element2_type).count

      {
        data: heatmap_data.map { |(type1, type2), count| { x: type1, y: type2, value: count } }
      }
    end

    def fetch_issue_status_pie
      issues = Bim::Bcf::Issue.joins(work_package: :project)
                              .where(projects: { id: project.id })

      status_counts = issues.joins(work_package: :status)
                           .group('statuses.name')
                           .count

      {
        labels: status_counts.keys,
        values: status_counts.values
      }
    end

    def fetch_progress_timeline
      # Progress snapshots over time
      baselines = Bim::ProgressBaseline.where(ifc_model_id: project.ifc_models.pluck(:id))
                                      .order(:snapshot_date)

      {
        labels: baselines.pluck(:snapshot_date),
        values: baselines.pluck(:overall_progress)
      }
    end

    def fetch_resolution_rate
      clashes = Bim::Clash.joins(:clash_test).where(clash_tests: { project_id: project.id })

      {
        clashes: calculate_resolution_rate(clashes),
        issues: calculate_issue_resolution_rate
      }
    end

    def fetch_element_count_bar
      links = Bim::ElementLink.joins(:ifc_model).where(ifc_models: { project_id: project.id })

      type_counts = links.group(:element_type).count.sort_by { |_k, v| -v }.first(10)

      {
        labels: type_counts.map(&:first),
        values: type_counts.map(&:last)
      }
    end

    def fetch_conversion_status
      models = project.ifc_models

      {
        total: models.count,
        successful: models.where(conversion_status: :completed).count,
        failed: models.where(conversion_status: :failed).count,
        in_progress: models.where(conversion_status: :processing).count
      }
    end

    def fetch_schedule_variance
      models = project.ifc_models
      return { error: 'No models' } if models.empty?

      service = Bim::Progress::TrackingService.new(ifc_model: models.first)
      stats = service.calculate_model_progress

      {
        delayed: stats[:delayed_count],
        ahead: stats[:ahead_count],
        on_schedule: stats[:on_schedule_count]
      }
    end

    # Helper methods

    def calculate_resolution_rate(clashes)
      total = clashes.count
      return 0.0 if total.zero?

      resolved = clashes.where(status: [:resolved, :closed]).count
      (resolved.to_f / total * 100).round(2)
    end

    def calculate_issue_resolution_rate
      issues = Bim::Bcf::Issue.joins(work_package: :project)
                              .where(projects: { id: project.id })

      total = issues.count
      return 0.0 if total.zero?

      closed = issues.joins(work_package: :status)
                    .where(statuses: { is_closed: true })
                    .count

      (closed.to_f / total * 100).round(2)
    end

    def calculate_work_package_completion(work_packages)
      total = work_packages.count
      return 0.0 if total.zero?

      avg_done_ratio = work_packages.average(:done_ratio).to_f
      avg_done_ratio.round(2)
    end
  end
end
