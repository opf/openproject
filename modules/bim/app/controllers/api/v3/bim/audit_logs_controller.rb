# frozen_string_literal: true

module API
  module V3
    module Bim
      class AuditLogsController < ApplicationController
        before_action :find_project
        before_action :authorize

        # GET /api/v3/projects/:project_id/bim/audit_logs
        def index
          logs = @project.audit_logs.recent

          # Apply filters
          logs = logs.for_action(params[:action_type]) if params[:action_type]
          logs = logs.for_user(params[:user_id]) if params[:user_id]
          logs = logs.since(params[:since]) if params[:since]

          # Pagination
          page = (params[:page] || 1).to_i
          per_page = (params[:per_page] || 25).to_i
          logs = logs.limit(per_page).offset((page - 1) * per_page)

          render json: {
            _type: 'Collection',
            total: @project.audit_logs.count,
            count: logs.size,
            page: page,
            per_page: per_page,
            _embedded: {
              elements: logs.map { |log| audit_log_representer(log) }
            }
          }
        end

        # GET /api/v3/projects/:project_id/bim/audit_logs/export
        def export
          service = ::Bim::Security::AuditService.new(user: current_user, project: @project)
          since = params[:since] ? Time.parse(params[:since]) : 30.days.ago

          csv_data = service.export_to_csv(since: since)

          send_data csv_data,
                    filename: "audit_logs_#{@project.identifier}_#{Date.today}.csv",
                    type: 'text/csv'
        end

        # GET /api/v3/projects/:project_id/bim/audit_logs/report
        def report
          service = ::Bim::Security::AuditService.new(user: current_user, project: @project)
          since = params[:since] ? Time.parse(params[:since]) : 30.days.ago

          report = service.generate_security_report(since: since)

          render json: {
            _type: 'SecurityReport',
            **report
          }
        end

        private

        def find_project
          @project = Project.find(params[:project_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Project not found' }, status: :not_found
        end

        def authorize
          unless current_user.admin? || current_user.allowed_in_project?(:manage_ifc_models, @project)
            render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end

        def audit_log_representer(log)
          {
            _type: 'AuditLog',
            id: log.id,
            timestamp: log.created_at.iso8601,
            user: log.user ? { id: log.user_id, name: log.user.name } : nil,
            action: log.action_type,
            action_description: log.action_description,
            details: log.details,
            ip_address: log.ip_address&.to_s,
            _links: {
              self: { href: "/api/v3/projects/#{@project.id}/bim/audit_logs/#{log.id}" },
              project: { href: "/api/v3/projects/#{@project.id}" }
            }
          }
        end
      end
    end
  end
end
