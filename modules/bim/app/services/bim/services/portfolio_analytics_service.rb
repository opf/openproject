# frozen_string_literal: true

module Bim
  module Services
    class PortfolioAnalyticsService
      attr_reader :date, :projects

      def initialize(date: Date.current, projects: nil)
        @date = date
        @projects = projects || Project.where(active: true)
      end

      # Collect all metrics for the portfolio
      def collect_all_metrics(user: nil)
        results = {
          date: @date,
          collected_at: Time.current,
          metrics_collected: 0,
          projects_processed: 0,
          errors: []
        }

        # Mark old metrics as stale
        Bim::PortfolioMetric.mark_stale!(older_than: 1.day.ago)

        # Collect portfolio-wide metrics
        collect_portfolio_metrics(user: user)
        results[:metrics_collected] += 1

        # Collect per-project metrics
        @projects.each do |project|
          begin
            collect_project_metrics(project, user: user)
            results[:projects_processed] += 1
            results[:metrics_collected] += count_project_metrics
          rescue => e
            results[:errors] << { project: project.name, error: e.message }
            Rails.logger.error "Error collecting metrics for project #{project.name}: #{e.message}"
          end
        end

        results
      end

      # Collect portfolio-wide aggregated metrics
      def collect_portfolio_metrics(user: nil)
        # Clash metrics
        collect_clash_metrics_portfolio(user: user)

        # Issue metrics
        collect_issue_metrics_portfolio(user: user)

        # Workflow metrics
        collect_workflow_metrics_portfolio(user: user)

        # Progress metrics
        collect_progress_metrics_portfolio(user: user)

        # Audit metrics
        collect_audit_metrics_portfolio(user: user)

        # Model metrics
        collect_model_metrics_portfolio(user: user)
      end

      # Collect project-specific metrics
      def collect_project_metrics(project, user: nil)
        # Clash metrics
        collect_clash_metrics_project(project, user: user)

        # Issue metrics
        collect_issue_metrics_project(project, user: user)

        # Workflow metrics
        collect_workflow_metrics_project(project, user: user)

        # Progress metrics
        collect_progress_metrics_project(project, user: user)

        # Audit metrics
        collect_audit_metrics_project(project, user: user)

        # Model metrics
        collect_model_metrics_project(project, user: user)
      end

      private

      # Portfolio-wide clash metrics
      def collect_clash_metrics_portfolio(user:)
        total_clashes = Bim::Clash.count
        resolved_clashes = Bim::Clash.where(status: :resolved).count
        critical_clashes = Bim::Clash.where(severity: :critical).count

        resolution_rate = total_clashes > 0 ? (resolved_clashes.to_f / total_clashes * 100) : 0

        store_metric(
          metric_type: 'clash',
          metric_name: 'resolution_rate',
          scope: 'portfolio',
          value: resolution_rate,
          unit: 'percentage',
          category: 'quality',
          details: {
            total_clashes: total_clashes,
            resolved_clashes: resolved_clashes,
            critical_clashes: critical_clashes
          },
          threshold_good: 80,
          threshold_warning: 60,
          user: user
        )

        # Average resolution time
        resolved_with_times = Bim::Clash.where(status: :resolved).where.not(resolved_at: nil, detected_at: nil)
        if resolved_with_times.any?
          avg_resolution_days = resolved_with_times.pluck(:detected_at, :resolved_at).map do |detected, resolved|
            ((resolved - detected) / 1.day).round(1)
          end.sum / resolved_with_times.count

          store_metric(
            metric_type: 'clash',
            metric_name: 'avg_resolution_time',
            scope: 'portfolio',
            value: avg_resolution_days,
            unit: 'days',
            category: 'performance',
            threshold_good: 7,
            threshold_warning: 14,
            user: user
          )
        end
      end

      # Project-specific clash metrics
      def collect_clash_metrics_project(project, user:)
        clashes = Bim::Clash.joins(ifc_model: :project).where(projects: { id: project.id })

        total = clashes.count
        return if total.zero?

        resolved = clashes.where(status: :resolved).count
        resolution_rate = (resolved.to_f / total * 100).round(2)

        store_metric(
          metric_type: 'clash',
          metric_name: 'resolution_rate',
          scope: 'project',
          project: project,
          value: resolution_rate,
          unit: 'percentage',
          category: 'quality',
          details: { total: total, resolved: resolved },
          threshold_good: 80,
          threshold_warning: 60,
          user: user
        )
      end

      # Portfolio-wide issue metrics
      def collect_issue_metrics_portfolio(user:)
        total_issues = Bim::Bcf::Issue.count
        closed_issues = Bim::Bcf::Issue.joins(:work_package).where(work_packages: { status_id: Status.where(is_closed: true).pluck(:id) }).count

        closure_rate = total_issues > 0 ? (closed_issues.to_f / total_issues * 100) : 0

        store_metric(
          metric_type: 'issue',
          metric_name: 'closure_rate',
          scope: 'portfolio',
          value: closure_rate,
          unit: 'percentage',
          category: 'collaboration',
          details: { total_issues: total_issues, closed_issues: closed_issues },
          threshold_good: 75,
          threshold_warning: 50,
          user: user
        )
      end

      # Project-specific issue metrics
      def collect_issue_metrics_project(project, user:)
        issues = Bim::Bcf::Issue.joins(:work_package).where(work_packages: { project_id: project.id })

        total = issues.count
        return if total.zero?

        closed = issues.where(work_packages: { status_id: Status.where(is_closed: true).pluck(:id) }).count
        closure_rate = (closed.to_f / total * 100).round(2)

        store_metric(
          metric_type: 'issue',
          metric_name: 'closure_rate',
          scope: 'project',
          project: project,
          value: closure_rate,
          unit: 'percentage',
          category: 'collaboration',
          details: { total: total, closed: closed },
          threshold_good: 75,
          threshold_warning: 50,
          user: user
        )
      end

      # Portfolio-wide workflow metrics
      def collect_workflow_metrics_portfolio(user:)
        # Workflow completion rate
        total_workflows = Bim::WorkflowLog.distinct.pluck(:workflowable_type, :workflowable_id).count
        completed_workflows = Bim::WorkflowLog.where(to_state: Bim::WorkflowTemplate.all.flat_map(&:final_states)).distinct.pluck(:workflowable_type, :workflowable_id).count

        completion_rate = total_workflows > 0 ? (completed_workflows.to_f / total_workflows * 100) : 0

        store_metric(
          metric_type: 'workflow',
          metric_name: 'completion_rate',
          scope: 'portfolio',
          value: completion_rate,
          unit: 'percentage',
          category: 'performance',
          threshold_good: 80,
          threshold_warning: 60,
          user: user
        )

        # Average approval time
        approval_logs = Bim::WorkflowLog.where(transition_name: 'approve').where.not(duration_in_state: nil)
        if approval_logs.any?
          avg_approval_hours = (approval_logs.average(:duration_in_state).to_f / 3600).round(1)

          store_metric(
            metric_type: 'workflow',
            metric_name: 'avg_approval_time',
            scope: 'portfolio',
            value: avg_approval_hours,
            unit: 'hours',
            category: 'performance',
            threshold_good: 24,
            threshold_warning: 48,
            user: user
          )
        end
      end

      # Project-specific workflow metrics
      def collect_workflow_metrics_project(project, user:)
        # Get workflows related to project entities
        workflow_logs = Bim::WorkflowLog.joins(:workflow_template).where(workflow_templates: { project_id: [project.id, nil] })

        return if workflow_logs.empty?

        total = workflow_logs.distinct.pluck(:workflowable_type, :workflowable_id).count
        completed = workflow_logs.where(to_state: Bim::WorkflowTemplate.all.flat_map(&:final_states)).distinct.pluck(:workflowable_type, :workflowable_id).count

        completion_rate = total > 0 ? (completed.to_f / total * 100).round(2) : 0

        store_metric(
          metric_type: 'workflow',
          metric_name: 'completion_rate',
          scope: 'project',
          project: project,
          value: completion_rate,
          unit: 'percentage',
          category: 'performance',
          threshold_good: 80,
          threshold_warning: 60,
          user: user
        )
      end

      # Portfolio-wide progress metrics
      def collect_progress_metrics_portfolio(user:)
        progresses = Bim::ElementProgress.all

        return if progresses.empty?

        avg_completion = progresses.average(:completion_percentage).to_f.round(2)

        store_metric(
          metric_type: 'progress',
          metric_name: 'avg_completion',
          scope: 'portfolio',
          value: avg_completion,
          unit: 'percentage',
          category: 'progress',
          threshold_good: 75,
          threshold_warning: 50,
          user: user
        )
      end

      # Project-specific progress metrics
      def collect_progress_metrics_project(project, user:)
        progresses = Bim::ElementProgress.joins(work_package: :project).where(projects: { id: project.id })

        return if progresses.empty?

        avg_completion = progresses.average(:completion_percentage).to_f.round(2)

        store_metric(
          metric_type: 'progress',
          metric_name: 'avg_completion',
          scope: 'project',
          project: project,
          value: avg_completion,
          unit: 'percentage',
          category: 'progress',
          threshold_good: 75,
          threshold_warning: 50,
          user: user
        )
      end

      # Portfolio-wide audit metrics
      def collect_audit_metrics_portfolio(user:)
        last_30_days = Bim::AuditLog.since(30.days.ago)

        total_actions = last_30_days.count
        security_actions = last_30_days.security_sensitive.count

        activity_rate = (total_actions.to_f / 30).round(2)

        store_metric(
          metric_type: 'audit',
          metric_name: 'daily_activity',
          scope: 'portfolio',
          value: activity_rate,
          unit: 'count',
          category: 'collaboration',
          details: {
            total_actions: total_actions,
            security_actions: security_actions
          },
          user: user
        )
      end

      # Project-specific audit metrics
      def collect_audit_metrics_project(project, user:)
        last_30_days = Bim::AuditLog.for_project(project.id).since(30.days.ago)

        total_actions = last_30_days.count
        return if total_actions.zero?

        activity_rate = (total_actions.to_f / 30).round(2)

        store_metric(
          metric_type: 'audit',
          metric_name: 'daily_activity',
          scope: 'project',
          project: project,
          value: activity_rate,
          unit: 'count',
          category: 'collaboration',
          user: user
        )
      end

      # Portfolio-wide model metrics
      def collect_model_metrics_portfolio(user:)
        total_models = Bim::IfcModels::IfcModel.count
        completed_models = Bim::IfcModels::IfcModel.where(conversion_status: :completed).count

        conversion_rate = total_models > 0 ? (completed_models.to_f / total_models * 100) : 0

        store_metric(
          metric_type: 'model',
          metric_name: 'conversion_rate',
          scope: 'portfolio',
          value: conversion_rate,
          unit: 'percentage',
          category: 'quality',
          details: { total: total_models, completed: completed_models },
          threshold_good: 95,
          threshold_warning: 85,
          user: user
        )
      end

      # Project-specific model metrics
      def collect_model_metrics_project(project, user:)
        models = Bim::IfcModels::IfcModel.where(project: project)

        total = models.count
        return if total.zero?

        completed = models.where(conversion_status: :completed).count
        conversion_rate = (completed.to_f / total * 100).round(2)

        store_metric(
          metric_type: 'model',
          metric_name: 'conversion_rate',
          scope: 'project',
          project: project,
          value: conversion_rate,
          unit: 'percentage',
          category: 'quality',
          details: { total: total, completed: completed },
          threshold_good: 95,
          threshold_warning: 85,
          user: user
        )
      end

      # Store or update a metric
      def store_metric(metric_type:, metric_name:, scope:, value:, project: nil, unit: nil, category: nil, discipline: nil, tags: [], details: {}, breakdown: {}, threshold_good: nil, threshold_warning: nil, user: nil)
        # Find existing metric for today or create new one
        metric = Bim::PortfolioMetric.find_or_initialize_by(
          metric_type: metric_type,
          metric_name: metric_name,
          metric_date: @date,
          project_id: project&.id,
          scope: scope
        )

        # Get previous value for trend calculation
        previous = Bim::PortfolioMetric.for_metric_type(metric_type)
                                       .for_metric_name(metric_name)
                                       .for_scope(scope)
                                       .where(project_id: project&.id)
                                       .where('metric_date < ?', @date)
                                       .order(metric_date: :desc)
                                       .first

        metric.previous_value = previous&.value if previous

        # Update attributes
        metric.value = value
        metric.unit = unit
        metric.category = category
        metric.discipline = discipline
        metric.tags = tags
        metric.details = details
        metric.breakdown = breakdown
        metric.threshold_good = threshold_good
        metric.threshold_warning = threshold_warning
        metric.collected_at = Time.current
        metric.collected_by = user
        metric.stale = false

        # Calculate derived fields
        metric.calculate_change
        metric.trend = metric.calculate_trend
        metric.status = metric.calculate_status

        metric.save!
        metric
      end

      def count_project_metrics
        # Count metrics per project (estimate)
        6 # clash, issue, workflow, progress, audit, model
      end
    end
  end
end
