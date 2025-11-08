# frozen_string_literal: true

module Bim
  module Security
    class AuditService
      def initialize(user:, project:)
        @user = user
        @project = project
      end

      # Log an action with automatic context capture
      def log_action(action:, details: {})
        Bim::AuditLog.log(
          user: @user,
          project: @project,
          action: action,
          details: details,
          ip_address: current_ip_address,
          user_agent: current_user_agent,
          request_id: current_request_id
        )
      end

      # Generate security report for project
      def generate_security_report(since: 30.days.ago)
        {
          project_id: @project.id,
          project_name: @project.name,
          report_period: {
            start: since,
            end: Time.current
          },
          activity_summary: Bim::AuditLog.activity_summary(@project.id, since: since),
          top_users: Bim::AuditLog.top_users(@project.id, since: since),
          security_sensitive_actions: security_sensitive_actions(since),
          total_actions: Bim::AuditLog.for_project(@project.id).since(since).count
        }
      end

      # Export audit logs to CSV
      def export_to_csv(since: 30.days.ago)
        logs = Bim::AuditLog.for_project(@project.id).since(since).recent
        Bim::AuditLog.to_csv(logs)
      end

      private

      def security_sensitive_actions(since)
        Bim::AuditLog.for_project(@project.id)
                    .since(since)
                    .select(&:security_sensitive?)
                    .map(&:to_hash)
      end

      def current_ip_address
        RequestStore.store[:current_user_ip] if defined?(RequestStore)
      end

      def current_user_agent
        RequestStore.store[:current_user_agent] if defined?(RequestStore)
      end

      def current_request_id
        RequestStore.store[:request_id] if defined?(RequestStore)
      end
    end
  end
end
