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
  # Service for batch clash detection operations across multiple models or runs
  #
  # Provides:
  # - Multi-model detection
  # - Scheduled detection runs
  # - Detection run comparison
  # - Bulk status updates
  # - Clash aging and cleanup
  #
  # Example:
  #   service = Bim::BatchClashDetectionService.new
  #   result = service.detect_across_models(project: project, options: { ... })
  #
  class BatchClashDetectionService
    ##
    # Detect clashes across all IFC models in a project
    #
    # @param project [Project] The project containing IFC models
    # @param options [Hash] Detection options to apply to all models
    # @return [ServiceResult] Result with detection summary
    #
    def detect_across_models(project:, options: {})
      ifc_models = project.ifc_models.where(is_default: true)

      return ServiceResult.failure(errors: ['No IFC models found in project']) if ifc_models.empty?

      detection_run_id = generate_detection_run_id
      results = []
      total_clashes = 0
      failed_models = []

      ifc_models.find_each do |ifc_model|
        service = ClashDetectionService.new(
          ifc_model: ifc_model,
          options: options.merge(detection_run_id: detection_run_id)
        )

        result = service.detect_all_clashes

        if result.success?
          results << {
            ifc_model_id: ifc_model.id,
            ifc_model_title: ifc_model.title,
            clash_count: result.result[:count],
            detection_time: result.result[:detection_time]
          }
          total_clashes += result.result[:count]
        else
          failed_models << {
            ifc_model_id: ifc_model.id,
            ifc_model_title: ifc_model.title,
            errors: result.errors
          }
        end
      end

      ServiceResult.success(
        result: {
          detection_run_id: detection_run_id,
          models_processed: results.size,
          models_failed: failed_models.size,
          total_clashes: total_clashes,
          results: results,
          failures: failed_models,
          timestamp: Time.current
        }
      )
    end

    ##
    # Compare clashes between two detection runs
    #
    # Identifies:
    # - New clashes (in run2, not in run1)
    # - Resolved clashes (in run1, not in run2)
    # - Persistent clashes (in both runs)
    #
    # @param ifc_model [Bim::IfcModels::IfcModel] The IFC model
    # @param run1_id [String] First detection run ID
    # @param run2_id [String] Second detection run ID
    # @return [ServiceResult] Comparison result
    #
    def compare_detection_runs(ifc_model:, run1_id:, run2_id:)
      run1_clashes = Bim::Clash.where(ifc_model: ifc_model, detection_run_id: run1_id)
      run2_clashes = Bim::Clash.where(ifc_model: ifc_model, detection_run_id: run2_id)

      return ServiceResult.failure(errors: ['Run 1 not found']) if run1_clashes.empty?
      return ServiceResult.failure(errors: ['Run 2 not found']) if run2_clashes.empty?

      # Create element pair sets for comparison
      run1_pairs = run1_clashes.map { |c| [c.element_a_id, c.element_b_id].sort }.to_set
      run2_pairs = run2_clashes.map { |c| [c.element_a_id, c.element_b_id].sort }.to_set

      new_pairs = run2_pairs - run1_pairs
      resolved_pairs = run1_pairs - run2_pairs
      persistent_pairs = run1_pairs & run2_pairs

      # Get actual clash records
      new_clashes = run2_clashes.select { |c| new_pairs.include?([c.element_a_id, c.element_b_id].sort) }
      resolved_clashes = run1_clashes.select { |c| resolved_pairs.include?([c.element_a_id, c.element_b_id].sort) }
      persistent_clashes = run2_clashes.select { |c| persistent_pairs.include?([c.element_a_id, c.element_b_id].sort) }

      ServiceResult.success(
        result: {
          run1_id: run1_id,
          run2_id: run2_id,
          run1_total: run1_clashes.count,
          run2_total: run2_clashes.count,
          new_count: new_clashes.size,
          resolved_count: resolved_clashes.size,
          persistent_count: persistent_clashes.size,
          new_clashes: new_clashes,
          resolved_clashes: resolved_clashes,
          persistent_clashes: persistent_clashes,
          improvement_rate: calculate_improvement_rate(run1_clashes.count, run2_clashes.count)
        }
      )
    end

    ##
    # Bulk update clash statuses based on criteria
    #
    # @param ifc_model [Bim::IfcModels::IfcModel] The IFC model
    # @param criteria [Hash] Selection criteria
    # @param new_status [Symbol] New status to apply
    # @return [ServiceResult] Update result
    #
    def bulk_status_update(ifc_model:, criteria: {}, new_status:)
      clashes = Bim::Clash.where(ifc_model: ifc_model)

      # Apply criteria filters
      clashes = clashes.where(clash_type: criteria[:clash_type]) if criteria[:clash_type]
      clashes = clashes.where(severity: criteria[:severity]) if criteria[:severity]
      clashes = clashes.where(status: criteria[:current_status]) if criteria[:current_status]

      updated_count = 0
      failed_count = 0
      errors = []

      clashes.find_each do |clash|
        if clash.update(status: new_status)
          updated_count += 1
        else
          failed_count += 1
          errors << { clash_id: clash.id, errors: clash.errors.full_messages }
        end
      end

      ServiceResult.success(
        result: {
          total_selected: clashes.count,
          updated_count: updated_count,
          failed_count: failed_count,
          errors: errors
        }
      )
    end

    ##
    # Archive or delete old clashes based on age and status
    #
    # @param ifc_model [Bim::IfcModels::IfcModel] The IFC model
    # @param older_than [Integer] Number of days
    # @param statuses [Array<Symbol>] Statuses to include in cleanup
    # @param action [Symbol] :archive or :delete
    # @return [ServiceResult] Cleanup result
    #
    def cleanup_old_clashes(ifc_model:, older_than: 90, statuses: [:resolved, :approved], action: :archive)
      cutoff_date = older_than.days.ago

      clashes = Bim::Clash
                  .where(ifc_model: ifc_model)
                  .where(status: statuses)
                  .where('detected_at < ?', cutoff_date)

      count = clashes.count

      case action
      when :archive
        clashes.update_all(status: :closed, closed_at: Time.current)
        message = "Archived #{count} old clashes"
      when :delete
        clashes.destroy_all
        message = "Deleted #{count} old clashes"
      else
        return ServiceResult.failure(errors: ["Invalid action: #{action}"])
      end

      ServiceResult.success(
        result: {
          action: action,
          count: count,
          cutoff_date: cutoff_date,
          message: message
        }
      )
    end

    ##
    # Get clash trends over time
    #
    # @param ifc_model [Bim::IfcModels::IfcModel] The IFC model
    # @param period [Symbol] :daily, :weekly, or :monthly
    # @param limit [Integer] Number of periods to include
    # @return [ServiceResult] Trend data
    #
    def clash_trends(ifc_model:, period: :weekly, limit: 12)
      case period
      when :daily
        group_clause = "DATE(detected_at)"
      when :weekly
        group_clause = "DATE_TRUNC('week', detected_at)"
      when :monthly
        group_clause = "DATE_TRUNC('month', detected_at)"
      else
        return ServiceResult.failure(errors: ["Invalid period: #{period}"])
      end

      trends = Bim::Clash
                 .where(ifc_model: ifc_model)
                 .group(group_clause)
                 .group(:severity)
                 .order(group_clause)
                 .limit(limit)
                 .count

      # Transform into more usable format
      formatted_trends = trends.each_with_object({}) do |((date, severity), count), hash|
        date_key = date.to_s
        hash[date_key] ||= { date: date, total: 0, by_severity: {} }
        hash[date_key][:by_severity][severity] = count
        hash[date_key][:total] += count
      end

      ServiceResult.success(
        result: {
          period: period,
          trends: formatted_trends.values,
          summary: {
            periods_analyzed: formatted_trends.size,
            total_clashes: formatted_trends.values.sum { |t| t[:total] }
          }
        }
      )
    end

    ##
    # Auto-assign clashes to work packages based on rules
    #
    # @param ifc_model [Bim::IfcModels::IfcModel] The IFC model
    # @param rules [Hash] Assignment rules
    # @return [ServiceResult] Assignment result
    #
    def auto_assign_to_work_packages(ifc_model:, rules: {})
      clashes = Bim::Clash.where(ifc_model: ifc_model, work_package_id: nil)

      # Filter by severity if specified
      clashes = clashes.where(severity: rules[:severities]) if rules[:severities]

      assigned_count = 0
      skipped_count = 0

      clashes.find_each do |clash|
        # Find or create work package based on rules
        work_package = find_or_create_work_package_for_clash(clash, rules)

        if work_package
          clash.update(work_package: work_package, assigned_to: work_package.assigned_to)
          assigned_count += 1
        else
          skipped_count += 1
        end
      end

      ServiceResult.success(
        result: {
          total_clashes: clashes.count,
          assigned_count: assigned_count,
          skipped_count: skipped_count
        }
      )
    end

    private

    ##
    # Generate unique detection run ID
    #
    def generate_detection_run_id
      "run_#{Time.current.to_i}_#{SecureRandom.hex(4)}"
    end

    ##
    # Calculate improvement rate between two runs
    #
    def calculate_improvement_rate(old_count, new_count)
      return 0.0 if old_count.zero?

      ((old_count - new_count).to_f / old_count * 100).round(2)
    end

    ##
    # Find or create work package for clash based on rules
    #
    def find_or_create_work_package_for_clash(clash, rules)
      # This is a simplified implementation
      # Real implementation would use more sophisticated rules

      return nil unless rules[:project] && rules[:type_id]

      # Check if there's already a work package for this element combination
      existing_wp = WorkPackage
                      .joins(:element_links)
                      .where(project: rules[:project])
                      .where('bim_element_links.element_id IN (?)', [clash.element_a_id, clash.element_b_id])
                      .first

      return existing_wp if existing_wp

      # Create new work package if auto_create is enabled
      return nil unless rules[:auto_create]

      WorkPackage.create!(
        project: rules[:project],
        type_id: rules[:type_id],
        subject: "Clash: #{clash.display_name}",
        description: "Auto-generated work package for #{clash.severity} #{clash.clash_type} clash",
        priority: priority_for_severity(clash.severity),
        assigned_to: rules[:assigned_to]
      )
    rescue StandardError => e
      Rails.logger.error("Failed to create work package for clash #{clash.id}: #{e.message}")
      nil
    end

    ##
    # Get priority for clash severity
    #
    def priority_for_severity(severity)
      case severity.to_sym
      when :critical
        IssuePriority.find_by(name: 'High') || IssuePriority.first
      when :major
        IssuePriority.find_by(name: 'Normal') || IssuePriority.first
      when :minor
        IssuePriority.find_by(name: 'Low') || IssuePriority.first
      else
        IssuePriority.first
      end
    end
  end
end
