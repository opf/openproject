# frozen_string_literal: true

module Bim
  class FederationModel < ApplicationRecord
    self.table_name = 'bim_federation_models'

    belongs_to :model_federation, class_name: 'Bim::ModelFederation', inverse_of: :federation_models
    belongs_to :ifc_model, class_name: 'Bim::IfcModels::IfcModel'

    # Discipline enum
    enum discipline: {
      architectural: 0,
      structural: 1,
      mechanical: 2,
      electrical: 3,
      plumbing: 4,
      civil: 5,
      landscape: 6,
      other: 99
    }

    validates :ifc_model_id, uniqueness: { scope: :model_federation_id }
    validates :discipline, presence: true
    validates :opacity, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }
    validates :display_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, allow_blank: true }

    # Scopes
    scope :visible, -> { where(visible: true) }
    scope :hidden, -> { where(visible: false) }
    scope :for_discipline, ->(disc) { where(discipline: disc) }
    scope :ordered_by_display, -> { order(display_order: :asc) }

    # Default colors per discipline
    DISCIPLINE_COLORS = {
      architectural: '#3498DB',   # Blue
      structural: '#E74C3C',      # Red
      mechanical: '#2ECC71',      # Green
      electrical: '#F39C12',      # Orange
      plumbing: '#9B59B6',        # Purple
      civil: '#95A5A6',           # Gray
      landscape: '#1ABC9C',       # Turquoise
      other: '#34495E'            # Dark gray
    }.freeze

    # Set default color based on discipline
    before_validation :set_default_color, on: :create, if: -> { color.blank? }

    # Calculate transformed extent (bounding box) after applying transformation
    # @return [Hash] { min: [x, y, z], max: [x, y, z] }
    def transformed_extent
      extent = extract_model_extent
      return extent if transform.blank?

      apply_transformation(extent, transform)
    end

    # Export configuration for frontend viewer
    # @return [Hash] viewer configuration
    def to_viewer_config
      {
        id: id,
        ifc_model_id: ifc_model.id,
        model_name: ifc_model.title,
        discipline: discipline,
        transform: transform || default_transform,
        visible: visible,
        color: color || DISCIPLINE_COLORS[discipline.to_sym],
        opacity: opacity || 1.0,
        display_order: display_order
      }
    end

    # Get transformation matrix in 4x4 format for viewer
    # @return [Array<Array<Float>>] 4x4 transformation matrix
    def transformation_matrix
      t = transform || default_transform
      translation = t['translation'] || [0, 0, 0]
      rotation = t['rotation'] || [0, 0, 0]
      scale = t['scale'] || [1, 1, 1]

      # Build 4x4 transformation matrix
      # This is a simplified version - full implementation would use proper matrix math
      [
        [scale[0], 0, 0, translation[0]],
        [0, scale[1], 0, translation[1]],
        [0, 0, scale[2], translation[2]],
        [0, 0, 0, 1]
      ]
    end

    # Human-readable discipline name
    # @return [String]
    def discipline_name
      discipline.titleize
    end

    private

    def set_default_color
      self.color = DISCIPLINE_COLORS[discipline.to_sym] if discipline.present?
    end

    def default_transform
      {
        'translation' => [0, 0, 0],
        'rotation' => [0, 0, 0],
        'scale' => [1, 1, 1]
      }
    end

    def extract_model_extent
      metadata = ifc_model.ifc_model_metadata
      return default_extent unless metadata

      # Try to get extent from spatial structure
      spatial = metadata.spatial_structure
      if spatial && spatial['extent']
        return {
          min: spatial['extent']['min'] || [0, 0, 0],
          max: spatial['extent']['max'] || [10, 10, 10]
        }
      end

      default_extent
    end

    def default_extent
      { min: [0, 0, 0], max: [10, 10, 10] }
    end

    def apply_transformation(extent, transform)
      translation = transform['translation'] || [0, 0, 0]
      # For simplicity, only apply translation
      # Full implementation would handle rotation and scale
      {
        min: [
          extent[:min][0] + translation[0],
          extent[:min][1] + translation[1],
          extent[:min][2] + translation[2]
        ],
        max: [
          extent[:max][0] + translation[0],
          extent[:max][1] + translation[1],
          extent[:max][2] + translation[2]
        ]
      }
    end
  end
end
