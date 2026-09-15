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
  class ElementProgress < ApplicationRecord
    self.table_name = 'bim_element_progresses'

    # Status enum
    enum status: {
      planned: 0,      # Not yet started
      in_progress: 1,  # Work in progress
      completed: 2,    # Fully completed
      on_hold: 3       # Temporarily paused
    }

    # Associations
    belongs_to :ifc_model, class_name: 'Bim::IfcModels::IfcModel'
    belongs_to :baseline, class_name: 'Bim::ProgressBaseline', optional: true
    belongs_to :work_package, class_name: 'WorkPackage', optional: true
    belongs_to :updated_by, class_name: 'User', optional: true

    # Validations
    validates :element_id, presence: true, length: { maximum: 255 }
    validates :ifc_model_id, presence: true
    validates :status, presence: true
    validates :percent_complete, presence: true,
                                  numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

    validate :actual_dates_after_planned
    validate :percent_complete_matches_status

    # Scopes
    scope :for_model, ->(model) { where(ifc_model: model) }
    scope :current, -> { where(baseline_id: nil) }
    scope :for_baseline, ->(baseline) { where(baseline: baseline) }
    scope :by_type, ->(type) { where(element_type: type) }
    scope :by_work_package, ->(wp) { where(work_package: wp) }
    scope :delayed, -> {
      where('actual_finish IS NOT NULL AND planned_finish IS NOT NULL AND actual_finish > planned_finish')
    }
    scope :ahead_of_schedule, -> {
      where('actual_finish IS NOT NULL AND planned_finish IS NOT NULL AND actual_finish < planned_finish')
    }
    scope :on_schedule, -> {
      where('actual_finish IS NOT NULL AND planned_finish IS NOT NULL AND actual_finish = planned_finish')
    }

    ##
    # Mark element as started
    #
    # @param user [User, nil] User who started the work
    # @return [Boolean]
    #
    def start!(user: nil)
      update(
        status: :in_progress,
        actual_start: Date.current,
        percent_complete: [percent_complete, 1].max, # At least 1%
        updated_by: user
      )
    end

    ##
    # Mark element as completed
    #
    # @param user [User, nil] User who completed the work
    # @return [Boolean]
    #
    def complete!(user: nil)
      update(
        status: :completed,
        percent_complete: 100,
        actual_finish: Date.current,
        updated_by: user
      )
    end

    ##
    # Put element on hold
    #
    # @param user [User, nil] User who put work on hold
    # @return [Boolean]
    #
    def hold!(user: nil)
      update(
        status: :on_hold,
        updated_by: user
      )
    end

    ##
    # Resume element from hold
    #
    # @param user [User, nil] User who resumed the work
    # @return [Boolean]
    #
    def resume!(user: nil)
      update(
        status: :in_progress,
        updated_by: user
      )
    end

    ##
    # Update progress percentage
    #
    # @param progress [Integer] New progress percentage (0-100)
    # @param user [User, nil] User who updated the progress
    # @return [Boolean]
    #
    def update_progress!(progress, user: nil)
      new_status = case progress
                   when 0
                     :planned
                   when 100
                     :completed
                   else
                     status == :planned ? :in_progress : status
                   end

      update(
        percent_complete: progress,
        status: new_status,
        actual_start: actual_start || (progress > 0 ? Date.current : nil),
        actual_finish: progress == 100 ? Date.current : nil,
        updated_by: user
      )
    end

    ##
    # Calculate schedule variance in days
    #
    # @return [Integer, nil] Positive = delayed, Negative = ahead
    #
    def schedule_variance_days
      return nil unless planned_finish && actual_finish

      (actual_finish - planned_finish).to_i
    end

    ##
    # Check if element is delayed
    #
    # @return [Boolean]
    #
    def delayed?
      return false unless schedule_variance_days

      schedule_variance_days > 0
    end

    ##
    # Check if element is ahead of schedule
    #
    # @return [Boolean]
    #
    def ahead_of_schedule?
      return false unless schedule_variance_days

      schedule_variance_days < 0
    end

    ##
    # Calculate duration (planned)
    #
    # @return [Integer, nil] Duration in days
    #
    def planned_duration_days
      return nil unless planned_start && planned_finish

      (planned_finish - planned_start).to_i
    end

    ##
    # Calculate actual duration
    #
    # @return [Integer, nil] Duration in days
    #
    def actual_duration_days
      return nil unless actual_start && actual_finish

      (actual_finish - actual_start).to_i
    end

    ##
    # Get element metadata from IFC model
    #
    # @return [Hash, nil]
    #
    def element_metadata
      ifc_model.metadata&.dig('elements', element_id)
    end

    ##
    # Get element name from metadata or stored value
    #
    # @return [String]
    #
    def display_name
      element_name || element_metadata&.dig('properties', 'name') || element_id
    end

    ##
    # Calculate progress variance against baseline
    #
    # @param baseline [ProgressBaseline, nil]
    # @return [Integer, nil]
    #
    def progress_variance_against(baseline_param = nil)
      baseline_param ||= baseline
      return nil unless baseline_param

      baseline_progress = self.class.find_by(
        ifc_model: ifc_model,
        element_id: element_id,
        baseline: baseline_param
      )

      return nil unless baseline_progress

      percent_complete - baseline_progress.percent_complete
    end

    ##
    # Check if element is complete
    #
    # @return [Boolean]
    #
    def complete?
      status == 'completed' && percent_complete == 100
    end

    ##
    # Check if element is in progress
    #
    # @return [Boolean]
    #
    def in_progress?
      status == 'in_progress'
    end

    ##
    # Check if work has started
    #
    # @return [Boolean]
    #
    def started?
      actual_start.present? || percent_complete > 0
    end

    ##
    # Get progress status color for visualization
    #
    # @return [String] Hex color code
    #
    def progress_color
      case status
      when 'completed'
        '#4caf50' # Green
      when 'in_progress'
        if delayed?
          '#f44336' # Red - delayed
        elsif ahead_of_schedule?
          '#2196f3' # Blue - ahead
        else
          '#ff9800' # Orange - on track
        end
      when 'on_hold'
        '#9e9e9e' # Gray
      else
        '#e0e0e0' # Light gray - planned
      end
    end

    private

    def actual_dates_after_planned
      if actual_start && planned_start && actual_start < planned_start
        errors.add(:actual_start, 'cannot be before planned start')
      end

      if actual_finish && actual_start && actual_finish < actual_start
        errors.add(:actual_finish, 'cannot be before actual start')
      end
    end

    def percent_complete_matches_status
      if status == 'completed' && percent_complete != 100
        errors.add(:percent_complete, 'must be 100 when status is completed')
      end

      if status == 'planned' && percent_complete > 0
        errors.add(:percent_complete, 'must be 0 when status is planned')
      end
    end
  end
end
