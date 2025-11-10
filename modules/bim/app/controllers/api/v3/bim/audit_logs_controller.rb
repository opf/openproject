# frozen_string_literal: true

module API
  module V3
    module Bim
      class AuditLogsController < ApplicationController
        DEFAULT_PER_PAGE = 25
        MAX_PER_PAGE = 200

        before_action :find_project, only: [:index, :export, :report, :timeline]
        before_action :authorize_view, only: [:index, :timeline]
        before_action :authorize_export, only: [:export, :report]
        before_action :find_audit_log, only: [:show, :verify]

        # GET /api/v3/projects/:project_id/bim/audit_logs
        def index
          logs = @project ? ::Bim::AuditLog.for_project(@project.id) : ::Bim::AuditLog.all

          # Apply filters
          logs = apply_filters(logs)

          # Pagination
          page = (params[:page] || 1).to_i
          per_page = [(params[:per_page] || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min
          total = logs.count
          logs = logs.limit(per_page).offset((page - 1) * per_page)

          render json: {
            _type: 'Collection',
            total: total,
            count: logs.size,
            page: page,
            per_page: per_page,
            _embedded: {
              elements: logs.map { |log| audit_log_representer(log) }
            },
            _links: {
              self: { href: request.original_url }
            }
          }
        end

        # GET /api/v3/bim/audit_logs/:id
        def show
          render json: audit_log_representer(@log, include_snapshots: true, include_changes: true)
        end

        # GET /api/v3/bim/audit_logs/:id/verify
        def verify
          valid = @log.verify_checksum

          render json: {
            _type: 'AuditLogVerification',
            id: @log.id,
            valid: valid,
            checksum: @log.checksum,
            message: valid ? 'Audit log integrity verified' : 'Checksum mismatch - possible tampering'
          }
        end

        # GET /api/v3/bim/audit_logs/entity/:entity_type/:entity_id/history
        def entity_history
          entity_type = params[:entity_type]
          entity_id = params[:entity_id]

          logs = ::Bim::AuditLog.entity_history(entity_type, entity_id)

          render json: {
            _type: 'EntityHistory',
            entity_type: entity_type,
            entity_id: entity_id,
            total_changes: logs.count,
            _embedded: {
              timeline: logs.map { |log| audit_log_representer(log, include_changes: true) }
            }
          }
        end

        # GET /api/v3/bim/audit_logs/entity/:entity_type/:entity_id/versions
        def entity_versions
          entity_type = params[:entity_type]
          entity_id = params[:entity_id]

          logs = ::Bim::AuditLog.entity_versions(entity_type, entity_id)

          render json: {
            _type: 'EntityVersions',
            entity_type: entity_type,
            entity_id: entity_id,
            total_versions: logs.count,
            current_version: logs.last&.entity_version,
            _embedded: {
              versions: logs.map do |log|
                {
                  version: log.entity_version,
                  previous_version: log.previous_version,
                  timestamp: log.created_at.iso8601,
                  user: log.user&.name,
                  action: log.action_type,
                  changes_count: log.changes.keys.count
                }
              end
            }
          }
        end

        # GET /api/v3/projects/:project_id/bim/audit_logs/timeline
        def timeline
          logs = ::Bim::AuditLog.for_project(@project.id).recent.limit(100).includes(:user)

          # Group by date
          grouped = logs.group_by { |log| log.created_at.to_date }

          render json: {
            _type: 'AuditTimeline',
            project_id: @project.id,
            project_name: @project.name,
            days: grouped.map do |date, day_logs|
              {
                date: date.iso8601,
                events_count: day_logs.count,
                events: day_logs.map { |log| audit_log_compact(log) }
              }
            end
          }
        end

        # GET /api/v3/projects/:project_id/bim/audit_logs/export
        def export
          logs = ::Bim::AuditLog.for_project(@project.id)
          logs = apply_filters(logs)

          format = params[:format] || 'csv'

          case format
          when 'csv'
            csv_data = ::Bim::AuditLog.to_csv(logs)
            send_data csv_data,
                      filename: "audit_logs_#{@project.identifier}_#{Date.today}.csv",
                      type: 'text/csv'
          when 'json'
            json_data = ::Bim::AuditLog.to_json_export(logs)
            send_data json_data,
                      filename: "audit_logs_#{@project.identifier}_#{Date.today}.json",
                      type: 'application/json'
          else
            render json: { error: "Invalid format: #{format}" }, status: :bad_request
          end

          # Log the export action
          ::Bim::AuditLog.log(
            user: current_user,
            project: @project,
            action: :export_data,
            details: {
              export_type: 'audit_logs',
              format: format,
              record_count: logs.count
            }
          )
        end

        # GET /api/v3/projects/:project_id/bim/audit_logs/report
        def report
          since = params[:since] ? Time.parse(params[:since]) : ::Bim::AuditLog::DEFAULT_ACTIVITY_PERIOD.ago
          logs = ::Bim::AuditLog.for_project(@project.id).since(since)

          report_data = {
            generated_at: Time.current.iso8601,
            project: @project.name,
            project_id: @project.id,
            period_start: since.iso8601,
            period_end: Time.current.iso8601,
            summary: {
              total_events: logs.count,
              unique_users: logs.pluck(:user_id).compact.uniq.count,
              security_events: logs.security_sensitive.count,
              data_changes: logs.with_changes.count,
              reversible_actions: logs.reversible.not_reversed.count
            },
            breakdown: {
              by_action: logs.group(:action_type).count,
              by_severity: logs.group(:severity).count
            },
            top_users: ::Bim::AuditLog.top_users(@project.id, since: since),
            recent_security_events: logs.security_sensitive.recent.limit(20).map { |log| audit_log_compact(log) }
          }

          render json: {
            _type: 'SecurityReport',
            **report_data
          }
        end

        private

        def find_project
          @project = Project.find(params[:project_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Project not found' }, status: :not_found
        end

        def find_audit_log
          @log = ::Bim::AuditLog.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Audit log not found' }, status: :not_found
        end

        def authorize_view
          unless current_user.admin? || (@project && current_user.allowed_in_project?(:view_ifc_models, @project))
            render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end

        def authorize_export
          unless current_user.admin? || (@project && current_user.allowed_in_project?(:manage_ifc_models, @project))
            render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end

        def apply_filters(logs)
          logs = logs.for_action(params[:action_type]) if params[:action_type]
          logs = logs.for_user(params[:user_id]) if params[:user_id]
          logs = logs.for_entity(params[:entity_type], params[:entity_id]) if params[:entity_type]
          logs = logs.by_severity(params[:severity]) if params[:severity]
          logs = logs.since(Time.parse(params[:since])) if params[:since]
          logs = logs.before(Time.parse(params[:before])) if params[:before]
          logs = logs.with_changes if params[:with_changes] == 'true'
          logs = logs.security_sensitive if params[:security_sensitive] == 'true'

          logs.recent
        end

        def audit_log_representer(log, include_snapshots: false, include_changes: false)
          data = {
            _type: 'AuditLog',
            id: log.id,
            timestamp: log.created_at.iso8601,
            formatted_timestamp: log.formatted_timestamp,
            user: log.user ? { id: log.user_id, name: log.user.name } : nil,
            project: { id: log.project_id, name: log.project.name },
            entity: log.entity_display,
            entity_type: log.entity_type,
            entity_id: log.entity_id,
            entity_version: log.entity_version,
            action: log.action_type,
            action_description: log.action_description,
            severity: log.severity,
            details: log.details,
            tags: log.tags,
            reversible: log.reversible,
            reversed: log.reversed?,
            checksum: log.checksum,
            ip_address: log.ip_address&.to_s,
            _links: {
              self: { href: "/api/v3/bim/audit_logs/#{log.id}" },
              project: { href: "/api/v3/projects/#{log.project_id}" }
            }
          }

          if include_changes
            data[:changes] = log.changes
            data[:changes_summary] = log.changes_summary
          end

          if include_snapshots && log.has_snapshots?
            data[:snapshot_before] = log.snapshot_before
            data[:snapshot_after] = log.snapshot_after
            data[:snapshot_diff] = log.snapshot_diff
          end

          data
        end

        def audit_log_compact(log)
          {
            id: log.id,
            timestamp: log.created_at.iso8601,
            user: log.user&.name,
            action: log.action_type,
            action_description: log.action_description,
            severity: log.severity
          }
        end
      end
    end
  end
end
