# frozen_string_literal: true

module Bim
  module Services
    class AuditTrailService
      attr_reader :enabled

      def initialize
        @enabled = true
        @snapshots_enabled = true
      end

      # Subscribe to all BIM domain events
      def self.subscribe_to_events!
        service = new

        # Model events
        subscribe_model_events(service)

        # Workflow events
        subscribe_workflow_events(service)

        # Issue events
        subscribe_issue_events(service)

        # Element events
        subscribe_element_events(service)

        # Clash events
        subscribe_clash_events(service)

        # System events
        subscribe_system_events(service)

        Rails.logger.info "BimAuditTrailService subscribed to all domain events"
      end

      # Model event subscriptions
      def self.subscribe_model_events(service)
        OpenProject::Notifications.subscribe('ifc_model_uploaded') do |payload|
          service.log_model_upload(payload)
        end

        OpenProject::Notifications.subscribe('ifc_model_deleted') do |payload|
          service.log_model_delete(payload)
        end

        OpenProject::Notifications.subscribe('ifc_conversion_started') do |payload|
          service.log_model_conversion_started(payload)
        end

        OpenProject::Notifications.subscribe('ifc_conversion_completed') do |payload|
          service.log_model_conversion_completed(payload)
        end

        OpenProject::Notifications.subscribe('ifc_conversion_failed') do |payload|
          service.log_model_conversion_failed(payload)
        end
      end

      # Workflow event subscriptions
      def self.subscribe_workflow_events(service)
        OpenProject::Notifications.subscribe('bim_workflow_transitioned') do |payload|
          service.log_workflow_transition(payload)
        end

        OpenProject::Notifications.subscribe('bim_workflow_initialized') do |payload|
          service.log_workflow_initialized(payload)
        end
      end

      # Issue event subscriptions
      def self.subscribe_issue_events(service)
        OpenProject::Notifications.subscribe('bim_issue_created') do |payload|
          service.log_issue_created(payload)
        end

        OpenProject::Notifications.subscribe('bim_issue_updated') do |payload|
          service.log_issue_updated(payload)
        end

        OpenProject::Notifications.subscribe('bim_comment_created') do |payload|
          service.log_issue_commented(payload)
        end
      end

      # Element event subscriptions
      def self.subscribe_element_events(service)
        OpenProject::Notifications.subscribe('bim_element_linked') do |payload|
          service.log_element_linked(payload)
        end

        OpenProject::Notifications.subscribe('bim_element_unlinked') do |payload|
          service.log_element_unlinked(payload)
        end

        OpenProject::Notifications.subscribe('bim_element_properties_refreshed') do |payload|
          service.log_element_properties_refreshed(payload)
        end
      end

      # Clash event subscriptions
      def self.subscribe_clash_events(service)
        OpenProject::Notifications.subscribe('bim_clash_detected') do |payload|
          service.log_clash_detection_run(payload)
        end

        OpenProject::Notifications.subscribe('bim_clash_resolved') do |payload|
          service.log_clash_resolved(payload)
        end

        OpenProject::Notifications.subscribe('bim_clash_approved') do |payload|
          service.log_clash_approved(payload)
        end
      end

      # System event subscriptions
      def self.subscribe_system_events(service)
        OpenProject::Notifications.subscribe('bim_cache_cleared') do |payload|
          service.log_cache_cleared(payload)
        end

        OpenProject::Notifications.subscribe('bim_export_data') do |payload|
          service.log_export_data(payload)
        end
      end

      # Logging methods

      def log_model_upload(payload)
        return unless enabled?

        model = payload[:model]
        user = payload[:user]

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: model.project,
          action: :model_upload,
          entity: model,
          details: {
            model_id: model.id,
            file_name: model.ifc_attachment&.filename,
            file_size: model.ifc_attachment&.filesize,
            uploader: user.name
          },
          severity: :info,
          tags: ['model', 'upload'],
          ip_address: payload[:ip_address],
          request_id: payload[:request_id]
        )
      end

      def log_model_delete(payload)
        return unless enabled?

        model_data = payload[:model_data]
        user = payload[:user]
        project = payload[:project]

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: project,
          action: :model_delete,
          entity_type: 'Bim::IfcModels::IfcModel',
          entity_id: model_data[:id],
          details: {
            model_id: model_data[:id],
            file_name: model_data[:title],
            deleted_by: user.name
          },
          snapshot_before: model_data,
          severity: :medium,
          reversible: false,
          tags: ['model', 'delete'],
          ip_address: payload[:ip_address],
          request_id: payload[:request_id]
        )
      end

      def log_model_conversion_started(payload)
        return unless enabled?

        model = payload[:model]
        user = payload[:user] || model.user

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: model.project,
          action: :model_conversion_started,
          entity: model,
          details: {
            model_id: model.id,
            file_name: model.title,
            conversion_started_at: Time.current.iso8601
          },
          severity: :info,
          tags: ['model', 'conversion', 'started']
        )
      end

      def log_model_conversion_completed(payload)
        return unless enabled?

        model = payload[:model]
        user = payload[:user] || model.user
        duration = payload[:duration]

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: model.project,
          action: :model_conversion_completed,
          entity: model,
          details: {
            model_id: model.id,
            file_name: model.title,
            duration_seconds: duration,
            cached: payload[:from_cache] == true
          },
          severity: :info,
          tags: ['model', 'conversion', 'completed']
        )
      end

      def log_model_conversion_failed(payload)
        return unless enabled?

        model = payload[:model]
        user = payload[:user] || model.user
        error = payload[:error]

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: model.project,
          action: :model_conversion_failed,
          entity: model,
          details: {
            model_id: model.id,
            file_name: model.title,
            error_message: error&.message,
            error_class: error&.class&.name
          },
          severity: :high,
          tags: ['model', 'conversion', 'failed', 'error']
        )
      end

      def log_workflow_transition(payload)
        return unless enabled?

        workflowable = payload[:workflowable]
        user = payload[:user]
        from_state = payload[:from_state]
        to_state = payload[:to_state]
        transition = payload[:transition]

        snapshot_before = @snapshots_enabled ? capture_snapshot(workflowable) : nil
        snapshot_after = snapshot_before&.merge('workflow_state' => to_state)

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: workflowable.respond_to?(:project) ? workflowable.project : workflowable.work_package&.project,
          action: :workflow_transitioned,
          entity: workflowable,
          details: {
            transition: transition,
            from_state: from_state,
            to_state: to_state,
            metadata: payload[:metadata]
          },
          changes: {
            workflow_state: [from_state, to_state]
          },
          snapshot_before: snapshot_before,
          snapshot_after: snapshot_after,
          severity: :info,
          reversible: true,
          tags: ['workflow', 'transition', transition.to_s]
        )
      end

      def log_workflow_initialized(payload)
        return unless enabled?

        workflowable = payload[:workflowable]
        user = payload[:user]
        template = payload[:template]

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: workflowable.respond_to?(:project) ? workflowable.project : workflowable.work_package&.project,
          action: :workflow_initialized,
          entity: workflowable,
          details: {
            template_id: template.id,
            template_name: template.name,
            initial_state: template.initial_state
          },
          severity: :info,
          reversible: true,
          tags: ['workflow', 'initialize']
        )
      end

      def log_issue_created(payload)
        return unless enabled?

        issue = payload[:issue]
        user = payload[:user]

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: issue.project,
          action: :issue_created,
          entity: issue,
          details: {
            issue_id: issue.id,
            title: issue.work_package&.subject,
            uuid: issue.uuid
          },
          snapshot_after: @snapshots_enabled ? capture_snapshot(issue) : nil,
          severity: :info,
          tags: ['issue', 'created']
        )
      end

      def log_issue_updated(payload)
        return unless enabled?

        issue = payload[:issue]
        user = payload[:user]
        changes = payload[:changes] || {}

        snapshot_before = payload[:snapshot_before] || (@snapshots_enabled ? capture_snapshot(issue, use_previous: true) : nil)
        snapshot_after = @snapshots_enabled ? capture_snapshot(issue) : nil

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: issue.project,
          action: :issue_updated,
          entity: issue,
          details: {
            issue_id: issue.id,
            title: issue.work_package&.subject,
            changed_attributes: changes.keys
          },
          changes: changes,
          snapshot_before: snapshot_before,
          snapshot_after: snapshot_after,
          severity: :info,
          reversible: true,
          tags: ['issue', 'updated']
        )
      end

      def log_issue_commented(payload)
        return unless enabled?

        comment = payload[:comment]
        user = payload[:user]
        issue = payload[:issue]

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: issue.project,
          action: :issue_commented,
          entity: issue,
          details: {
            issue_id: issue.id,
            comment_id: comment.id,
            comment_length: comment.journal&.notes&.length || 0
          },
          severity: :info,
          tags: ['issue', 'comment']
        )
      end

      def log_element_linked(payload)
        return unless enabled?

        element_link = payload[:element_link]
        user = payload[:user]

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: element_link.work_package.project,
          action: :element_linked,
          entity: element_link,
          details: {
            element_id: element_link.element_id,
            element_type: element_link.element_type,
            work_package_id: element_link.work_package_id,
            relationship_type: element_link.relationship_type
          },
          snapshot_after: @snapshots_enabled ? capture_snapshot(element_link) : nil,
          severity: :info,
          reversible: true,
          tags: ['element', 'linked']
        )
      end

      def log_element_unlinked(payload)
        return unless enabled?

        element_link_data = payload[:element_link_data]
        user = payload[:user]
        project = payload[:project]

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: project,
          action: :element_unlinked,
          entity_type: 'Bim::ElementLink',
          entity_id: element_link_data[:id],
          details: {
            element_id: element_link_data[:element_id],
            work_package_id: element_link_data[:work_package_id]
          },
          snapshot_before: element_link_data,
          severity: :info,
          reversible: true,
          tags: ['element', 'unlinked']
        )
      end

      def log_element_properties_refreshed(payload)
        return unless enabled?

        element_link = payload[:element_link]
        user = payload[:user]
        changes = payload[:changes] || {}

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: element_link.work_package.project,
          action: :element_properties_refreshed,
          entity: element_link,
          details: {
            element_id: element_link.element_id,
            properties_changed: !changes.empty?
          },
          changes: changes,
          severity: :info,
          tags: ['element', 'refresh']
        )
      end

      def log_clash_detection_run(payload)
        return unless enabled?

        project = payload[:project]
        user = payload[:user]
        clashes_found = payload[:clashes_found] || 0

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: project,
          action: :clash_detection_run,
          details: {
            clash_test_name: payload[:test_name],
            clashes_found: clashes_found,
            models_tested: payload[:models_tested]
          },
          severity: clashes_found > 0 ? :medium : :info,
          tags: ['clash', 'detection']
        )
      end

      def log_clash_resolved(payload)
        return unless enabled?

        clash = payload[:clash]
        user = payload[:user]

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: clash.ifc_model.project,
          action: :clash_resolved,
          entity: clash,
          details: {
            clash_id: clash.id,
            resolution_type: clash.resolution_type,
            resolution_comment: clash.resolution_comment
          },
          severity: :info,
          tags: ['clash', 'resolved']
        )
      end

      def log_clash_approved(payload)
        return unless enabled?

        clash = payload[:clash]
        user = payload[:user]

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: clash.ifc_model.project,
          action: :clash_approved,
          entity: clash,
          details: {
            clash_id: clash.id,
            approved_as: 'acceptable',
            approval_comment: clash.approval_comment
          },
          severity: :info,
          tags: ['clash', 'approved']
        )
      end

      def log_cache_cleared(payload)
        return unless enabled?

        user = payload[:user]
        project = payload[:project]

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: project,
          action: :cache_cleared,
          details: {
            cache_type: payload[:cache_type] || 'ifc_conversion',
            entries_cleared: payload[:entries_cleared] || 0
          },
          severity: :low,
          tags: ['system', 'cache', 'maintenance']
        )
      end

      def log_export_data(payload)
        return unless enabled?

        user = payload[:user]
        project = payload[:project]

        Bim::AuditLog.log_with_snapshot(
          user: user,
          project: project,
          action: :export_data,
          details: {
            export_type: payload[:export_type],
            record_count: payload[:record_count],
            format: payload[:format] || 'csv'
          },
          severity: :medium,
          tags: ['export', 'data', 'security']
        )
      end

      # Control methods

      def enable!
        @enabled = true
      end

      def disable!
        @enabled = false
      end

      def enabled?
        @enabled
      end

      def enable_snapshots!
        @snapshots_enabled = true
      end

      def disable_snapshots!
        @snapshots_enabled = false
      end

      private

      def capture_snapshot(entity, use_previous: false)
        return nil unless entity.respond_to?(:attributes)

        snapshot = entity.attributes.dup

        # Remove sensitive or unnecessary fields
        snapshot.delete('password')
        snapshot.delete('password_digest')

        # Add custom fields based on entity type
        case entity
        when Bim::Bcf::Issue
          snapshot['work_package_subject'] = entity.work_package&.subject
        when Bim::Clash
          snapshot['clash_type_label'] = entity.clash_type.humanize
          snapshot['severity_label'] = entity.severity.humanize
        when Bim::ElementLink
          snapshot['element_display_name'] = entity.display_name
          snapshot['element_display_type'] = entity.display_type
        end

        snapshot
      end
    end
  end
end
