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
  module Metrics
    ##
    # Service for aggregating BIM metrics and KPIs
    #
    # Collects comprehensive metrics from:
    # - IFC models (counts, sizes, conversion status)
    # - Clashes (totals, by status, resolution rates)
    # - BCF issues (trends, resolution times)
    # - Progress tracking (completion rates, variance)
    # - Work packages (BIM-linked packages, completion)
    #
    # Example:
    #   service = Bim::Metrics::AggregatorService.new(
    #     project: project,
    #     date_range: 30.days.ago..Time.current
    #   )
    #   metrics = service.call
    #
    class AggregatorService
      attr_reader :project, :date_range

      def initialize(project:, date_range: nil)
        @project = project
        @date_range = date_range || default_date_range
      end

      ##
      # Aggregate all metrics
      #
      # @return [Hash] Complete metrics hash
      #
      def call
        {
          timestamp: Time.current,
          project_id: project.id,
          date_range: {
            from: date_range.begin,
            to: date_range.end
          },
          models: model_metrics,
          clashes: clash_metrics,
          issues: issue_metrics,
          progress: progress_metrics,
          work_packages: work_package_metrics,
          summary: summary_metrics
        }
      end

      ##
      # Model-specific metrics
      #
      # @return [Hash]
      #
      def model_metrics
        models = project.ifc_models
        recent_models = models.where(created_at: date_range)

        {
          total: models.count,
          recent_uploads: recent_models.count,
          by_status: models.group(:conversion_status).count,
          total_size_mb: (models.sum(:file_size).to_f / 1.megabyte).round(2),
          avg_size_mb: models.any? ? (models.average(:file_size).to_f / 1.megabyte).round(2) : 0,
          largest_model: models.maximum(:file_size).to_f / 1.megabyte,
          conversion_success_rate: calculate_conversion_success_rate(models)
        }
      end

      ##
      # Clash detection metrics
      #
      # @return [Hash]
      #
      def clash_metrics
        tests = Bim::ClashTest.where(project: project)
        clashes = Bim::Clash.joins(:clash_test).where(clash_tests: { project_id: project.id })
        recent_clashes = clashes.where(created_at: date_range)

        {
          total_tests: tests.count,
          active_tests: tests.where(status: :active).count,
          total_clashes: clashes.count,
          new_clashes: clashes.where(status: :new).count,
          resolved_clashes: clashes.where(status: :resolved).count,
          recent_clashes: recent_clashes.count,
          by_status: clashes.group(:status).count,
          by_severity: clashes.group(:severity).count,
          by_discipline: discipline_clash_breakdown(clashes),
          resolution_rate: calculate_clash_resolution_rate(clashes),
          avg_resolution_time_days: calculate_avg_clash_resolution_time(clashes)
        }
      end

      ##
      # BCF issue metrics
      #
      # @return [Hash]
      #
      def issue_metrics
        issues = Bim::Bcf::Issue.joins(work_package: :project)
                                .where(projects: { id: project.id })

        recent_issues = issues.where(created_at: date_range)

        {
          total: issues.count,
          recent: recent_issues.count,
          open: issues.joins(work_package: :status)
                     .where.not(statuses: { is_closed: true })
                     .count,
          closed: issues.joins(work_package: :status)
                       .where(statuses: { is_closed: true })
                       .count,
          by_priority: issues.joins(work_package: :priority)
                            .group('priorities.name')
                            .count,
          by_type: issues.joins(work_package: :type)
                        .group('types.name')
                        .count,
          avg_resolution_time_hours: calculate_avg_issue_resolution_time(issues),
          trend: calculate_issue_trend(issues)
        }
      end

      ##
      # Progress tracking metrics
      #
      # @return [Hash]
      #
      def progress_metrics
        models = project.ifc_models
        return empty_progress_metrics if models.empty?

        # Use first model for progress (or aggregate across all models)
        model = models.first
        service = Bim::Progress::TrackingService.new(ifc_model: model)
        stats = service.calculate_model_progress

        baselines = Bim::ProgressBaseline.where(ifc_model_id: models.pluck(:id))

        {
          overall_progress: stats[:overall_progress],
          total_elements: stats[:total_elements],
          completed_elements: stats[:completed_elements],
          in_progress_elements: stats[:in_progress_elements],
          planned_elements: stats[:planned_elements],
          on_hold_elements: stats[:on_hold_elements],
          average_progress: stats[:average_progress],
          delayed_count: stats[:delayed_count],
          ahead_count: stats[:ahead_count],
          on_schedule_count: stats[:on_schedule_count],
          baselines_count: baselines.count,
          current_baseline: baselines.find_by(is_current: true)&.name
        }
      rescue StandardError
        empty_progress_metrics
      end

      ##
      # Work package metrics
      #
      # @return [Hash]
      #
      def work_package_metrics
        work_packages = project.work_packages
        recent_wps = work_packages.where(created_at: date_range)

        {
          total: work_packages.count,
          recent: recent_wps.count,
          with_bim_links: work_packages.joins(:element_links).distinct.count,
          bim_linkage_rate: calculate_bim_linkage_rate(work_packages),
          by_status: work_packages.joins(:status)
                                 .group('statuses.name')
                                 .count,
          by_type: work_packages.group(:type_id).count,
          avg_completion: work_packages.average(:done_ratio).to_f.round(2),
          overdue: work_packages.where('due_date < ?', Date.current)
                               .where.not(status_id: Status.where(is_closed: true).ids)
                               .count
        }
      end

      ##
      # Summary metrics (high-level KPIs)
      #
      # @return [Hash]
      #
      def summary_metrics
        {
          health_score: calculate_project_health_score,
          activity_level: calculate_activity_level,
          quality_score: calculate_quality_score,
          collaboration_score: calculate_collaboration_score
        }
      end

      private

      def default_date_range
        30.days.ago..Time.current
      end

      # Calculation helpers

      def calculate_conversion_success_rate(models)
        total = models.count
        return 0.0 if total.zero?

        successful = models.where(conversion_status: :completed).count
        (successful.to_f / total * 100).round(2)
      end

      def discipline_clash_breakdown(clashes)
        breakdown = {}

        clashes.group_by { |c| [c.element1_type, c.element2_type].sort }.each do |types, clash_group|
          key = types.join(' ↔ ')
          breakdown[key] = clash_group.size
        end

        breakdown.sort_by { |_k, v| -v }.first(10).to_h
      end

      def calculate_clash_resolution_rate(clashes)
        total = clashes.count
        return 0.0 if total.zero?

        resolved = clashes.where(status: [:resolved, :closed]).count
        (resolved.to_f / total * 100).round(2)
      end

      def calculate_avg_clash_resolution_time(clashes)
        resolved_clashes = clashes.where(status: [:resolved, :closed])
                                 .where.not(resolved_at: nil)

        return 0.0 if resolved_clashes.empty?

        total_time = resolved_clashes.sum do |clash|
          (clash.resolved_at - clash.created_at) / 1.day
        end

        (total_time / resolved_clashes.count).round(2)
      end

      def calculate_avg_issue_resolution_time(issues)
        closed_issues = issues.joins(work_package: :status)
                             .where(statuses: { is_closed: true })

        return 0.0 if closed_issues.empty?

        total_time = closed_issues.sum do |issue|
          wp = issue.work_package
          next 0 unless wp.updated_at

          (wp.updated_at - issue.created_at) / 1.hour
        end

        (total_time / closed_issues.count).round(2)
      end

      def calculate_issue_trend(issues)
        # Last 7 days
        (0..6).map do |days_ago|
          date = Date.current - days_ago.days
          count = issues.where(created_at: date.beginning_of_day..date.end_of_day).count
          { date: date, count: count }
        end.reverse
      end

      def calculate_bim_linkage_rate(work_packages)
        total = work_packages.count
        return 0.0 if total.zero?

        with_links = work_packages.joins(:element_links).distinct.count
        (with_links.to_f / total * 100).round(2)
      end

      def empty_progress_metrics
        {
          overall_progress: 0.0,
          total_elements: 0,
          completed_elements: 0,
          in_progress_elements: 0,
          planned_elements: 0,
          on_hold_elements: 0,
          average_progress: 0.0,
          delayed_count: 0,
          ahead_count: 0,
          on_schedule_count: 0,
          baselines_count: 0,
          current_baseline: nil
        }
      end

      # Composite score calculations

      def calculate_project_health_score
        scores = []

        # Clash resolution (25%)
        clash_score = clash_resolution_score
        scores << clash_score * 0.25

        # Issue resolution (25%)
        issue_score = issue_resolution_score
        scores << issue_score * 0.25

        # Progress (30%)
        progress_score = progress_completion_score
        scores << progress_score * 0.30

        # Schedule (20%)
        schedule_score = schedule_performance_score
        scores << schedule_score * 0.20

        scores.sum.round(2)
      end

      def clash_resolution_score
        tests = Bim::ClashTest.where(project: project)
        return 100.0 if tests.empty?

        clashes = Bim::Clash.joins(:clash_test).where(clash_tests: { project_id: project.id })
        calculate_clash_resolution_rate(clashes)
      end

      def issue_resolution_score
        issues = Bim::Bcf::Issue.joins(work_package: :project)
                                .where(projects: { id: project.id })

        return 100.0 if issues.empty?

        total = issues.count
        closed = issues.joins(work_package: :status)
                      .where(statuses: { is_closed: true })
                      .count

        (closed.to_f / total * 100).round(2)
      end

      def progress_completion_score
        models = project.ifc_models
        return 0.0 if models.empty?

        service = Bim::Progress::TrackingService.new(ifc_model: models.first)
        stats = service.calculate_model_progress

        stats[:overall_progress]
      rescue StandardError
        0.0
      end

      def schedule_performance_score
        models = project.ifc_models
        return 100.0 if models.empty?

        service = Bim::Progress::TrackingService.new(ifc_model: models.first)
        stats = service.calculate_model_progress

        total = stats[:total_elements]
        return 100.0 if total.zero?

        # Penalize for delayed elements
        delayed = stats[:delayed_count]
        ahead = stats[:ahead_count]

        base_score = 100.0
        base_score -= (delayed.to_f / total * 100).clamp(0, 50) # Max -50 for delays
        base_score += (ahead.to_f / total * 20).clamp(0, 20)    # Max +20 for being ahead

        base_score.clamp(0, 100).round(2)
      rescue StandardError
        100.0
      end

      def calculate_activity_level
        # Based on recent activities (last 7 days)
        recent_range = 7.days.ago..Time.current

        activity_count = 0
        activity_count += project.ifc_models.where(created_at: recent_range).count * 5 # Models weighted heavily
        activity_count += Bim::Clash.joins(:clash_test)
                                    .where(clash_tests: { project_id: project.id })
                                    .where(created_at: recent_range)
                                    .count
        activity_count += Bim::Bcf::Issue.joins(work_package: :project)
                                         .where(projects: { id: project.id })
                                         .where(created_at: recent_range)
                                         .count

        # Classify activity level
        case activity_count
        when 0 then 'inactive'
        when 1..5 then 'low'
        when 6..15 then 'moderate'
        when 16..30 then 'high'
        else 'very_high'
        end
      end

      def calculate_quality_score
        # Based on clash density and issue density
        models = project.ifc_models
        return 100.0 if models.empty?

        clashes = Bim::Clash.joins(:clash_test).where(clash_tests: { project_id: project.id })
        issues = Bim::Bcf::Issue.joins(work_package: :project).where(projects: { id: project.id })

        # Calculate density (issues per model)
        clash_density = clashes.count.to_f / models.count
        issue_density = issues.count.to_f / models.count

        # Lower density = higher quality
        quality_score = 100.0
        quality_score -= (clash_density * 2).clamp(0, 40)  # Max -40
        quality_score -= (issue_density * 3).clamp(0, 40)  # Max -40

        quality_score.clamp(0, 100).round(2)
      end

      def calculate_collaboration_score
        # Based on BIM linkage rate and issue activity
        work_packages = project.work_packages
        return 0.0 if work_packages.empty?

        # BIM linkage rate (60% weight)
        linkage_score = calculate_bim_linkage_rate(work_packages) * 0.6

        # Issue activity (40% weight)
        issues = Bim::Bcf::Issue.joins(work_package: :project).where(projects: { id: project.id })
        issue_activity = issues.any? ? 40.0 : 0.0

        (linkage_score + issue_activity).round(2)
      end
    end
  end
end
