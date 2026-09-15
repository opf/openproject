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
  module Progress
    ##
    # Service for managing element progress tracking
    #
    # Handles:
    # - Bulk progress updates
    # - Progress sync from work packages
    # - Baseline comparisons
    # - Progress calculations
    #
    # Example:
    #   service = Bim::Progress::TrackingService.new(ifc_model: model)
    #   result = service.update_element_progress(
    #     element_id: 'wall-1',
    #     percent_complete: 50,
    #     user: current_user
    #   )
    #
    class TrackingService
      attr_reader :ifc_model, :user

      def initialize(ifc_model:, user: nil)
        @ifc_model = ifc_model
        @user = user
      end

      ##
      # Update progress for a single element
      #
      # @param element_id [String]
      # @param percent_complete [Integer] 0-100
      # @param status [Symbol, nil] Optional status override
      # @param attributes [Hash] Additional attributes
      # @return [ServiceResult]
      #
      def update_element_progress(element_id:, percent_complete:, status: nil, **attributes)
        progress = find_or_create_progress(element_id)

        update_attrs = attributes.merge(
          percent_complete: percent_complete,
          updated_by: user
        )

        # Auto-determine status if not provided
        unless status
          status = determine_status(percent_complete, progress.status)
        end
        update_attrs[:status] = status if status

        # Set dates based on status
        update_attrs.merge!(status_date_updates(status, progress))

        if progress.update(update_attrs)
          ServiceResult.success(result: progress)
        else
          ServiceResult.failure(errors: progress.errors)
        end
      rescue StandardError => e
        ServiceResult.failure(errors: e.message)
      end

      ##
      # Bulk update progress for multiple elements
      #
      # @param updates [Array<Hash>] Array of {element_id:, percent_complete:, ...}
      # @return [ServiceResult]
      #
      def bulk_update_progress(updates)
        results = { succeeded: [], failed: [] }

        ActiveRecord::Base.transaction do
          updates.each do |update_params|
            result = update_element_progress(**update_params.symbolize_keys)

            if result.success?
              results[:succeeded] << result.result
            else
              results[:failed] << { element_id: update_params[:element_id], errors: result.errors }
            end
          end

          # Rollback if any failures (all-or-nothing)
          raise ActiveRecord::Rollback if results[:failed].any?
        end

        if results[:failed].empty?
          ServiceResult.success(result: results[:succeeded])
        else
          ServiceResult.failure(errors: results[:failed])
        end
      end

      ##
      # Sync progress from linked work packages
      #
      # Updates element progress based on work package completion percentages
      #
      # @return [ServiceResult]
      #
      def sync_from_work_packages
        synced_count = 0
        errors = []

        ElementProgress.for_model(ifc_model).where.not(work_package_id: nil).find_each do |progress|
          wp = progress.work_package
          next unless wp

          # Calculate work package completion percentage
          wp_percent = calculate_work_package_percent(wp)

          if progress.update(percent_complete: wp_percent, updated_by: user)
            synced_count += 1
          else
            errors << { element_id: progress.element_id, errors: progress.errors.full_messages }
          end
        end

        if errors.empty?
          ServiceResult.success(result: { synced_count: synced_count })
        else
          ServiceResult.failure(errors: errors)
        end
      end

      ##
      # Calculate overall model progress statistics
      #
      # @return [Hash] Statistics hash
      #
      def calculate_model_progress
        progresses = ElementProgress.current.for_model(ifc_model)

        total = progresses.count
        return default_progress_stats if total.zero?

        completed = progresses.where(status: :completed).count
        in_progress = progresses.where(status: :in_progress).count
        planned = progresses.where(status: :planned).count
        on_hold = progresses.where(status: :on_hold).count

        avg_progress = progresses.average(:percent_complete).to_f.round(2)
        overall_percent = (completed.to_f / total * 100).round(2)

        delayed = progresses.delayed.count
        ahead = progresses.ahead_of_schedule.count

        {
          total_elements: total,
          completed_elements: completed,
          in_progress_elements: in_progress,
          planned_elements: planned,
          on_hold_elements: on_hold,
          average_progress: avg_progress,
          overall_progress: overall_percent,
          delayed_count: delayed,
          ahead_count: ahead,
          on_schedule_count: total - delayed - ahead - planned
        }
      end

      ##
      # Compare current progress to a baseline
      #
      # @param baseline [ProgressBaseline]
      # @return [Hash] Comparison results
      #
      def compare_to_baseline(baseline)
        return nil unless baseline

        current_stats = calculate_model_progress
        baseline_progresses = ElementProgress.for_baseline(baseline).for_model(ifc_model)

        variance = current_stats[:overall_progress] - baseline.overall_progress
        element_changes = []

        ElementProgress.current.for_model(ifc_model).find_each do |current_progress|
          baseline_progress = baseline_progresses.find_by(element_id: current_progress.element_id)
          next unless baseline_progress

          progress_delta = current_progress.percent_complete - baseline_progress.percent_complete

          if progress_delta != 0
            element_changes << {
              element_id: current_progress.element_id,
              element_name: current_progress.display_name,
              baseline_progress: baseline_progress.percent_complete,
              current_progress: current_progress.percent_complete,
              variance: progress_delta
            }
          end
        end

        {
          baseline_name: baseline.name,
          baseline_date: baseline.snapshot_date,
          baseline_progress: baseline.overall_progress,
          current_progress: current_stats[:overall_progress],
          variance: variance,
          element_changes: element_changes.sort_by { |c| -c[:variance].abs }
        }
      end

      ##
      # Reset all progress for the model
      #
      # @return [ServiceResult]
      #
      def reset_all_progress
        ElementProgress.current.for_model(ifc_model).destroy_all
        ServiceResult.success(result: { message: 'All progress reset' })
      rescue StandardError => e
        ServiceResult.failure(errors: e.message)
      end

      private

      def find_or_create_progress(element_id)
        ElementProgress.find_or_create_by!(
          ifc_model: ifc_model,
          element_id: element_id,
          baseline_id: nil # Current progress
        ) do |progress|
          # Initialize from IFC metadata
          metadata = ifc_model.metadata&.dig('elements', element_id)
          progress.element_type = metadata&.dig('properties', 'type')
          progress.element_name = metadata&.dig('properties', 'name')
          progress.status = :planned
          progress.percent_complete = 0
        end
      end

      def determine_status(percent_complete, current_status)
        case percent_complete
        when 0
          :planned
        when 100
          :completed
        else
          current_status == 'planned' ? :in_progress : current_status
        end
      end

      def status_date_updates(status, progress)
        updates = {}

        case status.to_sym
        when :in_progress
          updates[:actual_start] = Date.current unless progress.actual_start
        when :completed
          updates[:actual_finish] = Date.current
          updates[:actual_start] = Date.current unless progress.actual_start
        end

        updates
      end

      def calculate_work_package_percent(work_package)
        # If work package has done_ratio, use it
        return work_package.done_ratio if work_package.respond_to?(:done_ratio) && work_package.done_ratio

        # Otherwise check status
        if work_package.status&.is_closed?
          100
        else
          0
        end
      end

      def default_progress_stats
        {
          total_elements: 0,
          completed_elements: 0,
          in_progress_elements: 0,
          planned_elements: 0,
          on_hold_elements: 0,
          average_progress: 0.0,
          overall_progress: 0.0,
          delayed_count: 0,
          ahead_count: 0,
          on_schedule_count: 0
        }
      end
    end
  end
end
