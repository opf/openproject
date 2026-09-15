# frozen_string_literal: true

module Bim
  class PortfolioMetricsCollectorJob < ApplicationJob
    queue_as :default

    # Run nightly to collect portfolio metrics
    # Schedule: Daily at 2:00 AM
    # Usage: Bim::PortfolioMetricsCollectorJob.perform_later

    def perform(date: nil, project_ids: nil, user_id: nil)
      date ||= Date.current
      user = user_id ? User.find_by(id: user_id) : User.system

      projects = if project_ids
                   Project.where(id: project_ids, active: true)
                 else
                   Project.where(active: true)
                 end

      Rails.logger.info "Starting portfolio metrics collection for #{date} across #{projects.count} projects"

      analytics = Bim::Services::PortfolioAnalyticsService.new(
        date: date,
        projects: projects
      )

      results = analytics.collect_all_metrics(user: user)

      # Log results
      Rails.logger.info "Portfolio metrics collection completed: #{results[:metrics_collected]} metrics collected, #{results[:projects_processed]} projects processed"

      if results[:errors].any?
        Rails.logger.warn "Portfolio metrics collection had #{results[:errors].count} errors: #{results[:errors].inspect}"
      end

      # Log to audit trail
      Bim::AuditLog.log(
        user: user,
        action: :portfolio_metrics_collected,
        details: {
          date: date,
          projects_processed: results[:projects_processed],
          metrics_collected: results[:metrics_collected],
          errors_count: results[:errors].count,
          scheduled: true
        },
        severity: results[:errors].any? ? :medium : :info,
        tags: ['portfolio', 'metrics', 'scheduled']
      )

      # Send notification if there were errors
      if results[:errors].any? && admin_users.any?
        send_error_notification(results)
      end

      results
    rescue StandardError => e
      Rails.logger.error "Portfolio metrics collection failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Log failure to audit trail
      Bim::AuditLog.log(
        user: user || User.system,
        action: :portfolio_metrics_collection_failed,
        details: {
          date: date,
          error: e.message,
          backtrace: e.backtrace.first(5)
        },
        severity: :high,
        tags: ['portfolio', 'metrics', 'error']
      )

      raise
    end

    private

    def admin_users
      @admin_users ||= User.admin.active
    end

    def send_error_notification(results)
      # TODO: Implement email notification for admins
      # This could use ActionMailer or internal notification system
      Rails.logger.info "Would send error notification to #{admin_users.count} admins"
    end
  end
end
