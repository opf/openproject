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
  class ProgressBaseline < ApplicationRecord
    self.table_name = 'bim_progress_baselines'

    # Status enum
    enum status: {
      active: 0,    # Active baseline
      archived: 1   # Archived/historical baseline
    }

    # Associations
    belongs_to :project
    belongs_to :created_by, class_name: 'User', optional: true
    has_many :element_progresses, class_name: 'Bim::ElementProgress', foreign_key: :baseline_id, dependent: :destroy

    # Validations
    validates :name, presence: true, length: { maximum: 255 }
    validates :snapshot_date, presence: true
    validates :project_id, presence: true
    validates :total_elements, numericality: { greater_than_or_equal_to: 0 }
    validates :completed_elements, numericality: { greater_than_or_equal_to: 0 }
    validates :in_progress_elements, numericality: { greater_than_or_equal_to: 0 }
    validates :planned_elements, numericality: { greater_than_or_equal_to: 0 }
    validates :overall_progress, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

    validate :only_one_current_baseline_per_project, if: :is_current?

    # Scopes
    scope :for_project, ->(project) { where(project: project) }
    scope :current, -> { where(is_current: true) }
    scope :recent, ->(days = 30) { where('created_at > ?', days.days.ago) }
    scope :by_date, -> { order(snapshot_date: :desc) }

    ##
    # Create baseline snapshot from current progress
    #
    # @return [Boolean]
    #
    def create_snapshot!
      transaction do
        project.ifc_models.each do |model|
          # Get current progress for all elements
          current_progresses = Bim::ElementProgress.where(ifc_model: model, baseline_id: nil)

          current_progresses.each do |progress|
            element_progresses.create!(
              ifc_model: model,
              element_id: progress.element_id,
              element_type: progress.element_type,
              element_name: progress.element_name,
              status: progress.status,
              percent_complete: progress.percent_complete,
              planned_start: progress.planned_start,
              planned_finish: progress.planned_finish,
              actual_start: progress.actual_start,
              actual_finish: progress.actual_finish,
              work_package: progress.work_package,
              custom_data: progress.custom_data,
              notes: progress.notes
            )
          end
        end

        # Update statistics
        update_statistics!
        true
      end
    end

    ##
    # Update baseline statistics
    #
    # @return [Boolean]
    #
    def update_statistics!
      stats = calculate_statistics

      update!(
        total_elements: stats[:total],
        completed_elements: stats[:completed],
        in_progress_elements: stats[:in_progress],
        planned_elements: stats[:planned],
        overall_progress: stats[:overall_progress]
      )
    end

    ##
    # Compare baseline to current progress
    #
    # @return [Hash] Comparison results
    #
    def compare_to_current
      variances = []
      total_variance = 0

      element_progresses.includes(:ifc_model).each do |baseline_elem|
        # Find current progress for this element
        current = Bim::ElementProgress.find_by(
          ifc_model: baseline_elem.ifc_model,
          element_id: baseline_elem.element_id,
          baseline_id: nil
        )

        next unless current

        variance = calculate_variance(baseline_elem, current)
        variances << variance
        total_variance += variance[:progress_variance]
      end

      {
        total_elements: element_progresses.count,
        elements_with_variance: variances.count { |v| v[:progress_variance] != 0 },
        ahead_of_schedule: variances.count { |v| v[:progress_variance] > 0 },
        behind_schedule: variances.count { |v| v[:progress_variance] < 0 },
        on_schedule: variances.count { |v| v[:progress_variance] == 0 },
        average_variance: variances.empty? ? 0 : (total_variance.to_f / variances.size).round(2),
        variances: variances
      }
    end

    ##
    # Set this baseline as current for the project
    #
    # @return [Boolean]
    #
    def set_as_current!
      transaction do
        # Unset any existing current baseline
        self.class.where(project: project, is_current: true).update_all(is_current: false)

        # Set this as current
        update!(is_current: true, status: :active)
      end
    end

    ##
    # Archive this baseline
    #
    # @return [Boolean]
    #
    def archive!
      update(status: :archived, is_current: false)
    end

    ##
    # Calculate overall completion percentage
    #
    # @return [Float]
    #
    def completion_percentage
      return 0.0 if total_elements.zero?

      (completed_elements.to_f / total_elements * 100).round(2)
    end

    ##
    # Get age in days
    #
    # @return [Integer]
    #
    def age_in_days
      (Date.current - snapshot_date).to_i
    end

    ##
    # Check if baseline is stale
    #
    # @param days_threshold [Integer]
    # @return [Boolean]
    #
    def stale?(days_threshold = 30)
      age_in_days > days_threshold
    end

    private

    def calculate_statistics
      total = element_progresses.count
      completed = element_progresses.where(status: :completed).count
      in_progress = element_progresses.where(status: :in_progress).count
      planned = element_progresses.where(status: :planned).count

      overall = if total.zero?
                  0.0
                else
                  (element_progresses.sum(:percent_complete).to_f / total).round(2)
                end

      {
        total: total,
        completed: completed,
        in_progress: in_progress,
        planned: planned,
        overall_progress: overall
      }
    end

    def calculate_variance(baseline_elem, current_elem)
      progress_variance = current_elem.percent_complete - baseline_elem.percent_complete

      schedule_variance = if baseline_elem.planned_finish && current_elem.actual_finish
                            (current_elem.actual_finish - baseline_elem.planned_finish).to_i
                          else
                            nil
                          end

      {
        element_id: baseline_elem.element_id,
        element_type: baseline_elem.element_type,
        element_name: baseline_elem.element_name,
        baseline_progress: baseline_elem.percent_complete,
        current_progress: current_elem.percent_complete,
        progress_variance: progress_variance,
        baseline_status: baseline_elem.status,
        current_status: current_elem.status,
        schedule_variance_days: schedule_variance
      }
    end

    def only_one_current_baseline_per_project
      existing = self.class.where(project: project, is_current: true).where.not(id: id).exists?
      if existing
        errors.add(:base, 'Only one current baseline allowed per project')
      end
    end
  end
end
