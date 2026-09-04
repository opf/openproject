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
  class Clash < ApplicationRecord
    self.table_name = 'bim_clashes'

    # Clash types define the nature of the geometric conflict
    enum clash_type: {
      hard: 0,        # Physical intersection/overlap
      soft: 1,        # Clearance violation (too close)
      clearance: 2,   # Minimum distance violation
      workflow: 3     # Construction sequence conflict
    }

    # Severity levels indicate the importance of the clash
    enum severity: {
      critical: 0,  # Must be resolved immediately
      major: 1,     # Should be resolved soon
      minor: 2      # Can be resolved later or accepted
    }

    # Status tracks the clash resolution lifecycle
    enum status: {
      new: 0,       # Just detected, not yet reviewed
      active: 1,    # Acknowledged, needs resolution
      approved: 2,  # Reviewed and accepted as-is
      resolved: 3,  # Fixed/addressed
      closed: 4     # Archived/no longer relevant
    }

    # Resolution types describe how the clash was addressed
    enum resolution_type: {
      redesign: 0,      # Elements were redesigned
      accepted: 1,      # Clash accepted as minor/acceptable
      relocated: 2,     # Elements were moved
      removed: 3,       # One element was removed
      phased: 4,        # Construction phasing eliminates conflict
      false_positive: 5 # Clash was incorrectly detected
    }, _prefix: :resolved_by

    # Associations
    belongs_to :ifc_model, class_name: 'Bim::IfcModels::IfcModel'
    belongs_to :work_package, class_name: 'WorkPackage', optional: true
    belongs_to :assigned_to, class_name: 'User', optional: true
    belongs_to :approved_by, class_name: 'User', optional: true
    belongs_to :resolved_by, class_name: 'User', optional: true

    # Validations
    validates :element_a_id, presence: true, length: { maximum: 50 }
    validates :element_b_id, presence: true, length: { maximum: 50 }
    validates :clash_type, presence: true
    validates :severity, presence: true
    validates :status, presence: true
    validates :detected_at, presence: true

    validate :elements_are_different
    validate :element_order_consistency
    validate :validate_approval_data
    validate :validate_resolution_data

    # Callbacks
    before_validation :normalize_element_order, on: :create

    # Scopes
    scope :for_element, ->(element_id) {
      where('element_a_id = ? OR element_b_id = ?', element_id, element_id)
    }
    scope :between_elements, ->(elem_a, elem_b) {
      where(
        '(element_a_id = ? AND element_b_id = ?) OR (element_a_id = ? AND element_b_id = ?)',
        elem_a, elem_b, elem_b, elem_a
      )
    }
    scope :in_detection_run, ->(run_id) { where(detection_run_id: run_id) }
    scope :unresolved, -> { where.not(status: [:resolved, :closed]) }
    scope :needing_attention, -> { where(status: [:new, :active]) }
    scope :by_severity_order, -> { order(severity: :asc, detected_at: :desc) }
    scope :recent, ->(days = 7) { where('detected_at > ?', days.days.ago) }
    scope :assigned, -> { where.not(assigned_to_id: nil) }
    scope :unassigned, -> { where(assigned_to_id: nil) }

    # Get element metadata from IFC model
    def element_a_metadata
      @element_a_metadata ||= ifc_model.metadata&.dig('elements', element_a_id)
    end

    def element_b_metadata
      @element_b_metadata ||= ifc_model.metadata&.dig('elements', element_b_id)
    end

    # Get element names for display
    def element_a_name
      element_a_metadata&.dig('properties', 'name') || element_a_id
    end

    def element_b_name
      element_b_metadata&.dig('properties', 'name') || element_b_id
    end

    # Get element types
    def element_a_type
      element_a_metadata&.dig('properties', 'type') || 'Unknown'
    end

    def element_b_type
      element_b_metadata&.dig('properties', 'type') || 'Unknown'
    end

    # Display name for the clash
    def display_name
      "#{element_a_type} vs #{element_b_type}"
    end

    # Check if clash involves a specific element
    def involves_element?(element_id)
      element_a_id == element_id || element_b_id == element_id
    end

    # Get both element IDs as an array
    def element_ids
      [element_a_id, element_b_id]
    end

    # Check if clash is a hard clash (physical intersection)
    def hard_clash?
      clash_type == 'hard'
    end

    # Check if clash is unresolved
    def unresolved?
      !resolved? && !closed?
    end

    # Approve the clash (accept as-is)
    def approve!(user:, comment: nil)
      update(
        status: :approved,
        approved_by: user,
        approved_at: Time.current,
        approval_comment: comment
      )
    end

    # Mark clash as resolved
    def resolve!(user:, resolution_type:, comment: nil)
      update(
        status: :resolved,
        resolved_by: user,
        resolved_at: Time.current,
        resolution_type: resolution_type,
        resolution_comment: comment
      )
    end

    # Reopen a resolved or approved clash
    def reopen!
      update(
        status: :active,
        approved_by: nil,
        approved_at: nil,
        approval_comment: nil,
        resolved_by: nil,
        resolved_at: nil,
        resolution_type: nil,
        resolution_comment: nil
      )
    end

    # Close clash (archive)
    def close!
      update(status: :closed)
    end

    # Assign to a user
    def assign!(user)
      update(assigned_to: user, status: :active)
    end

    # Create or link work package for resolution
    def create_work_package!(attributes = {})
      default_attributes = {
        project: ifc_model.project,
        subject: "Resolve clash: #{display_name}",
        description: generate_work_package_description,
        priority: priority_from_severity
      }

      wp = WorkPackage.create!(default_attributes.merge(attributes))
      update(work_package: wp)
      wp
    end

    # Calculate clash severity score (0-100, higher = more severe)
    def severity_score
      base_score = case severity
                   when 'critical' then 100
                   when 'major' then 50
                   when 'minor' then 20
                   end

      # Adjust for clash type
      type_multiplier = case clash_type
                        when 'hard' then 1.0
                        when 'soft' then 0.8
                        when 'clearance' then 0.6
                        when 'workflow' then 0.7
                        end

      # Adjust for overlap volume (if hard clash)
      volume_bonus = if hard_clash? && overlap_volume.present? && overlap_volume > 0
                       [overlap_volume * 10, 20].min
                     else
                       0
                     end

      (base_score * type_multiplier + volume_bonus).to_i
    end

    # Get clash location as 3D point
    def clash_location
      return nil unless clash_point.present?

      [
        clash_point['x'] || clash_point[:x],
        clash_point['y'] || clash_point[:y],
        clash_point['z'] || clash_point[:z]
      ].compact
    end

    # Check if clash is between specific types
    def between_types?(type_a, type_b)
      (element_a_type == type_a && element_b_type == type_b) ||
        (element_a_type == type_b && element_b_type == type_a)
    end

    # Get age of clash in days
    def age_in_days
      ((Time.current - detected_at) / 1.day).to_i
    end

    # Check if clash is stale (older than threshold)
    def stale?(days_threshold = 30)
      age_in_days > days_threshold && unresolved?
    end

    private

    def elements_are_different
      if element_a_id == element_b_id
        errors.add(:base, 'Element A and Element B must be different')
      end
    end

    def element_order_consistency
      # Ensure elements are always stored in consistent order (A < B alphabetically)
      # This is handled by before_validation callback
    end

    def normalize_element_order
      # Store elements in alphabetical order to prevent duplicates
      if element_a_id.present? && element_b_id.present? && element_a_id > element_b_id
        self.element_a_id, self.element_b_id = element_b_id, element_a_id
      end
    end

    def validate_approval_data
      if approved? && approved_by.blank?
        errors.add(:approved_by, 'must be present when status is approved')
      end

      if approved_by.present? && !approved?
        errors.add(:base, 'Approval data present but status is not approved')
      end
    end

    def validate_resolution_data
      if resolved? && resolved_by.blank?
        errors.add(:resolved_by, 'must be present when status is resolved')
      end

      if resolved? && resolution_type.blank?
        errors.add(:resolution_type, 'must be present when status is resolved')
      end
    end

    def generate_work_package_description
      <<~DESC
        # Clash Detection Result

        **Clash Type:** #{clash_type.humanize}
        **Severity:** #{severity.humanize}
        **Detected:** #{detected_at.strftime('%Y-%m-%d %H:%M')}

        ## Elements Involved

        **Element A:**
        - ID: #{element_a_id}
        - Name: #{element_a_name}
        - Type: #{element_a_type}

        **Element B:**
        - ID: #{element_b_id}
        - Name: #{element_b_name}
        - Type: #{element_b_type}

        ## Clash Details

        #{clash_details_text}

        ## Required Action

        Review the clash in the 3D viewer and determine the appropriate resolution:
        - Redesign one or both elements
        - Accept if clash is minor/acceptable
        - Adjust construction phasing
        - Relocate elements
      DESC
    end

    def clash_details_text
      details = []

      if distance.present?
        details << "- Distance: #{distance.round(2)}mm#{distance < 0 ? ' (overlapping)' : ''}"
      end

      if overlap_volume.present? && overlap_volume > 0
        details << "- Overlap Volume: #{overlap_volume.round(2)} cubic units"
      end

      if clash_location
        details << "- Location: (#{clash_location.map { |v| v.round(2) }.join(', ')})"
      end

      details.join("\n")
    end

    def priority_from_severity
      case severity
      when 'critical'
        IssuePriority.find_or_create_by!(name: 'Immediate', position: 3)
      when 'major'
        IssuePriority.find_or_create_by!(name: 'High', position: 2)
      when 'minor'
        IssuePriority.find_or_create_by!(name: 'Normal', position: 1)
      end
    end
  end
end
