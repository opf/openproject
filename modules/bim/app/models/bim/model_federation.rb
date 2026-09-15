# frozen_string_literal: true

module Bim
  class ModelFederation < ApplicationRecord
    self.table_name = 'bim_model_federations'

    belongs_to :project
    has_many :federation_models,
             class_name: 'Bim::FederationModel',
             foreign_key: :model_federation_id,
             dependent: :destroy,
             inverse_of: :model_federation
    has_many :ifc_models,
             through: :federation_models,
             class_name: 'Bim::IfcModels::IfcModel'

    validates :name, presence: true, length: { maximum: 255 }
    validates :project, presence: true
    validates :units, inclusion: { in: %w[meters feet millimeters], allow_blank: true }

    # Scopes
    scope :for_project, ->(project_id) { where(project_id: project_id) }
    scope :ordered, -> { order(created_at: :desc) }
    scope :recent, -> { ordered.limit(10) }

    # Returns all completed IFC models in the federation
    def load_all_models
      ifc_models.where(conversion_status: :completed)
    end

    # Groups federation models by discipline
    # @return [Hash] discipline => array of federation_models
    def models_by_discipline
      federation_models.includes(:ifc_model).group_by(&:discipline)
    end

    # Calculate the overall spatial extent of all models in the federation
    # @return [Hash] { min: [x, y, z], max: [x, y, z] }
    def spatial_extent
      extents = federation_models.includes(:ifc_model).map(&:transformed_extent).compact
      return default_extent if extents.empty?

      combine_extents(extents)
    end

    # Get viewer configuration for multi-model loading
    # @return [Hash] Configuration object for frontend viewer
    def viewer_config
      {
        federation_id: id,
        name: name,
        base_point: base_point || { x: 0, y: 0, z: 0 },
        rotation: rotation || { x: 0, y: 0, z: 0 },
        units: units || 'meters',
        models: federation_models.visible.ordered_by_display.map(&:to_viewer_config)
      }
    end

    # Statistics about the federation
    # @return [Hash] count, disciplines, total_elements
    def statistics
      {
        model_count: federation_models.count,
        disciplines: federation_models.group(:discipline).count,
        total_elements: ifc_models.sum { |m| m.ifc_model_metadata&.element_count || 0 },
        visible_models: federation_models.visible.count
      }
    end

    private

    def default_extent
      { min: [0, 0, 0], max: [10, 10, 10] }
    end

    def combine_extents(extents)
      {
        min: [
          extents.map { |e| e[:min][0] }.min,
          extents.map { |e| e[:min][1] }.min,
          extents.map { |e| e[:min][2] }.min
        ],
        max: [
          extents.map { |e| e[:max][0] }.max,
          extents.map { |e| e[:max][1] }.max,
          extents.map { |e| e[:max][2] }.max
        ]
      }
    end
  end
end
