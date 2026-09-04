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
  class ModelComparison < ApplicationRecord
    self.table_name = 'bim_model_comparisons'

    # Comparison types
    enum comparison_type: {
      version: 'version',         # Version comparison (model1 vs model2)
      baseline: 'baseline',       # Baseline comparison (saved baseline vs current)
      federated: 'federated'      # Federated model set comparison
    }, _suffix: true

    # Status tracking
    enum status: {
      pending: 0,     # Comparison created, not yet run
      completed: 1,   # Comparison finished
      approved: 2,    # Changes approved
      rejected: 3     # Changes rejected
    }

    # Associations
    belongs_to :model1, class_name: 'Bim::IfcModels::IfcModel', foreign_key: :model1_id
    belongs_to :model2, class_name: 'Bim::IfcModels::IfcModel', foreign_key: :model2_id
    belongs_to :created_by, class_name: 'User', optional: true
    belongs_to :approved_by, class_name: 'User', optional: true

    # Validations
    validates :model1_id, presence: true
    validates :model2_id, presence: true
    validates :comparison_type, presence: true
    validates :status, presence: true
    validates :added_count, numericality: { greater_than_or_equal_to: 0 }
    validates :deleted_count, numericality: { greater_than_or_equal_to: 0 }
    validates :modified_count, numericality: { greater_than_or_equal_to: 0 }
    validates :unchanged_count, numericality: { greater_than_or_equal_to: 0 }

    validate :models_are_different
    validate :models_in_same_project
    validate :validate_approval_data

    # Scopes
    scope :for_model, ->(model) {
      where('model1_id = ? OR model2_id = ?', model.id, model.id)
    }
    scope :between_models, ->(model1, model2) {
      where(
        '(model1_id = ? AND model2_id = ?) OR (model1_id = ? AND model2_id = ?)',
        model1.id, model2.id, model2.id, model1.id
      )
    }
    scope :recent, ->(days = 7) { where('created_at > ?', days.days.ago) }
    scope :by_change_count, -> { order(Arel.sql('(added_count + deleted_count + modified_count) DESC')) }
    scope :with_changes, -> {
      where('added_count > 0 OR deleted_count > 0 OR modified_count > 0')
    }
    scope :without_changes, -> {
      where(added_count: 0, deleted_count: 0, modified_count: 0)
    }

    ##
    # Calculate total number of changes
    #
    # @return [Integer] Sum of added, deleted, and modified elements
    #
    def total_changes
      added_count + deleted_count + modified_count
    end

    ##
    # Check if comparison has any changes
    #
    # @return [Boolean]
    #
    def has_changes?
      total_changes > 0
    end

    ##
    # Calculate total elements compared
    #
    # @return [Integer]
    #
    def total_elements
      added_count + deleted_count + modified_count + unchanged_count
    end

    ##
    # Calculate change percentage
    #
    # @return [Float] Percentage of elements that changed
    #
    def change_percentage
      return 0.0 if total_elements.zero?

      (total_changes.to_f / total_elements * 100).round(2)
    end

    ##
    # Get added elements from changes_data
    #
    # @return [Array<Hash>]
    #
    def added_elements
      changes_data['added'] || []
    end

    ##
    # Get deleted elements from changes_data
    #
    # @return [Array<Hash>]
    #
    def deleted_elements
      changes_data['deleted'] || []
    end

    ##
    # Get modified elements from changes_data
    #
    # @return [Array<Hash>]
    #
    def modified_elements
      changes_data['modified'] || []
    end

    ##
    # Get unchanged elements from changes_data
    #
    # @return [Array<Hash>]
    #
    def unchanged_elements
      changes_data['unchanged'] || []
    end

    ##
    # Approve the comparison
    #
    # @param user [User] The approving user
    # @param comment [String, nil] Optional approval comment
    # @return [Boolean]
    #
    def approve!(user:, comment: nil)
      update(
        status: :approved,
        approved_by: user,
        approved_at: Time.current,
        status_comment: comment
      )
    end

    ##
    # Reject the comparison
    #
    # @param user [User] The rejecting user
    # @param comment [String, nil] Optional rejection comment
    # @return [Boolean]
    #
    def reject!(user:, comment: nil)
      update(
        status: :rejected,
        approved_by: user,
        approved_at: Time.current,
        status_comment: comment
      )
    end

    ##
    # Mark comparison as completed
    #
    # @param time [Float, nil] Comparison execution time
    # @return [Boolean]
    #
    def complete!(time: nil)
      update(
        status: :completed,
        completed_at: Time.current,
        comparison_time: time
      )
    end

    ##
    # Get summary of changes by type
    #
    # @return [Hash]
    #
    def change_summary
      {
        added: added_count,
        deleted: deleted_count,
        modified: modified_count,
        unchanged: unchanged_count,
        total: total_elements,
        percentage: change_percentage
      }
    end

    ##
    # Get change breakdown by element type
    #
    # @return [Hash] Element types grouped with their change counts
    #
    def changes_by_type
      return {} unless changes_data.present?

      result = Hash.new { |h, k| h[k] = { added: 0, deleted: 0, modified: 0 } }

      # Count added elements by type
      added_elements.each do |elem|
        type = elem.dig('element', 'properties', 'type') || 'Unknown'
        result[type][:added] += 1
      end

      # Count deleted elements by type
      deleted_elements.each do |elem|
        type = elem.dig('element', 'properties', 'type') || 'Unknown'
        result[type][:deleted] += 1
      end

      # Count modified elements by type
      modified_elements.each do |elem|
        type = elem.dig('element', 'properties', 'type') || 'Unknown'
        result[type][:modified] += 1
      end

      result
    end

    ##
    # Get changes for specific element type
    #
    # @param element_type [String] IFC element type (e.g., 'IfcWall')
    # @return [Hash] Changes for the specified type
    #
    def changes_for_type(element_type)
      {
        added: added_elements.select { |e| e.dig('element', 'properties', 'type') == element_type },
        deleted: deleted_elements.select { |e| e.dig('element', 'properties', 'type') == element_type },
        modified: modified_elements.select { |e| e.dig('element', 'properties', 'type') == element_type }
      }
    end

    ##
    # Get most significant changes (sorted by impact)
    #
    # @param limit [Integer] Number of changes to return
    # @return [Array<Hash>]
    #
    def significant_changes(limit: 10)
      all_changes = []

      # Deleted elements are most significant
      deleted_elements.each do |elem|
        all_changes << elem.merge(change_type: 'deleted', significance: 3)
      end

      # Added elements are next
      added_elements.each do |elem|
        all_changes << elem.merge(change_type: 'added', significance: 2)
      end

      # Modified elements are least significant
      modified_elements.each do |elem|
        change_count = elem['changes']&.size || 0
        all_changes << elem.merge(change_type: 'modified', significance: 1, change_count: change_count)
      end

      all_changes
        .sort_by { |c| [-c[:significance], -(c[:change_count] || 0)] }
        .first(limit)
    end

    ##
    # Generate human-readable description
    #
    # @return [String]
    #
    def generate_description
      parts = []

      parts << "#{added_count} added" if added_count > 0
      parts << "#{deleted_count} deleted" if deleted_count > 0
      parts << "#{modified_count} modified" if modified_count > 0

      if parts.empty?
        "No changes detected"
      else
        "Comparison found: #{parts.join(', ')} elements"
      end
    end

    ##
    # Check if comparison is complete
    #
    # @return [Boolean]
    #
    def complete?
      completed? || approved? || rejected?
    end

    ##
    # Get age in days
    #
    # @return [Integer]
    #
    def age_in_days
      ((Time.current - created_at) / 1.day).to_i
    end

    ##
    # Check if comparison is stale
    #
    # @param days_threshold [Integer]
    # @return [Boolean]
    #
    def stale?(days_threshold = 30)
      age_in_days > days_threshold
    end

    private

    def models_are_different
      if model1_id.present? && model2_id.present? && model1_id == model2_id
        errors.add(:base, 'Cannot compare a model with itself')
      end
    end

    def models_in_same_project
      return unless model1 && model2

      if model1.project_id != model2.project_id
        errors.add(:base, 'Models must be in the same project')
      end
    end

    def validate_approval_data
      if approved? && approved_by.blank?
        errors.add(:approved_by, 'must be present when status is approved')
      end

      if rejected? && approved_by.blank?
        errors.add(:approved_by, 'must be present when status is rejected')
      end
    end
  end
end
