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
  module IfcModels
    ##
    # IFC Model Metadata
    #
    # Stores comprehensive metadata extracted from IFC files including:
    # - IFC version and schema information
    # - Entity and geometry counts
    # - Spatial structure hierarchy
    # - Property sets (Psets)
    # - Quantities (QTO)
    # - Classifications
    # - Materials
    # - Types/Families
    # - Validation results
    #
    # Example:
    #   metadata = IFCModelMetadata.create!(
    #     ifc_model: model,
    #     ifc_version: 'IFC4',
    #     entity_count: 45000,
    #     spatial_structure: { ... }
    #   )
    #
    class IfcModelMetadata < ApplicationRecord
      self.table_name = 'bim_ifc_model_metadata'

      belongs_to :ifc_model, class_name: 'Bim::IfcModels::IfcModel', foreign_key: 'ifc_model_id'

      # Validations
      validates :ifc_model_id, presence: true, uniqueness: true
      validates :entity_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
      validates :geometry_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
      validates :estimated_conversion_time, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
      validates :actual_conversion_time, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

      # Scopes
      scope :by_version, ->(version) { where(ifc_version: version) }
      scope :by_checksum, ->(checksum) { where(file_checksum: checksum) }
      scope :with_entities_count_above, ->(count) { where('entity_count > ?', count) }
      scope :recently_created, -> { order(created_at: :desc) }

      ##
      # Get duplicate models based on file checksum
      #
      # @return [ActiveRecord::Relation<IfcModelMetadata>]
      #
      def duplicates
        return self.class.none unless file_checksum.present?

        self.class.where(file_checksum: file_checksum).where.not(id: id)
      end

      ##
      # Check if this is a duplicate of another model
      #
      # @return [Boolean]
      #
      def duplicate?
        duplicates.exists?
      end

      ##
      # Get spatial structure as a tree
      #
      # @return [Hash]
      #
      def spatial_tree
        spatial_structure.presence || {}
      end

      ##
      # Get all building storeys
      #
      # @return [Array<Hash>]
      #
      def building_storeys
        extract_elements_by_type('IfcBuildingStorey')
      end

      ##
      # Get all spaces
      #
      # @return [Array<Hash>]
      #
      def spaces
        extract_elements_by_type('IfcSpace')
      end

      ##
      # Get property set by name
      #
      # @param pset_name [String]
      # @return [Hash, nil]
      #
      def property_set(pset_name)
        property_sets[pset_name]
      end

      ##
      # Get all property set names
      #
      # @return [Array<String>]
      #
      def property_set_names
        property_sets.keys
      end

      ##
      # Get quantity by name
      #
      # @param qty_name [String]
      # @return [Numeric, nil]
      #
      def quantity(qty_name)
        quantities[qty_name]
      end

      ##
      # Get total area
      #
      # @return [Float]
      #
      def total_area
        quantities.dig('total_area')&.to_f || 0.0
      end

      ##
      # Get total volume
      #
      # @return [Float]
      #
      def total_volume
        quantities.dig('total_volume')&.to_f || 0.0
      end

      ##
      # Get classification by system
      #
      # @param system [String] e.g., 'Uniclass', 'OmniClass'
      # @return [Array]
      #
      def classification(system)
        classifications[system] || []
      end

      ##
      # Get all materials
      #
      # @return [Array<Hash>]
      #
      def material_list
        materials['materials'] || []
      end

      ##
      # Get material by name
      #
      # @param name [String]
      # @return [Hash, nil]
      #
      def material(name)
        material_list.find { |m| m['name'] == name }
      end

      ##
      # Get type counts
      #
      # @return [Hash]
      #
      def type_counts
        types.transform_values { |v| v['count'] || 0 }
      end

      ##
      # Get validation warnings
      #
      # @return [Array<String>]
      #
      def validation_warnings
        validation_result['warnings'] || []
      end

      ##
      # Get validation errors
      #
      # @return [Array<String>]
      #
      def validation_errors
        validation_result['errors'] || []
      end

      ##
      # Check if validation passed
      #
      # @return [Boolean]
      #
      def validation_passed?
        validation_errors.empty?
      end

      ##
      # Get complexity score (0.0 - 1.0)
      #
      # @return [Float]
      #
      def complexity_score
        validation_result['complexity_score']&.to_f || 0.0
      end

      ##
      # Check if model is complex
      #
      # @return [Boolean]
      #
      def complex?
        complexity_score > 0.7
      end

      ##
      # Get conversion efficiency (actual / estimated)
      #
      # @return [Float, nil]
      #
      def conversion_efficiency
        return nil unless actual_conversion_time && estimated_conversion_time && estimated_conversion_time > 0

        actual_conversion_time.to_f / estimated_conversion_time
      end

      ##
      # Check if conversion was faster than estimated
      #
      # @return [Boolean]
      #
      def conversion_faster_than_estimated?
        return false unless conversion_efficiency

        conversion_efficiency < 1.0
      end

      ##
      # Check if metadata is complete
      #
      # @return [Boolean]
      #
      def complete?
        ifc_version.present? && entity_count.present? && spatial_structure.present?
      end

      ##
      # Get summary statistics
      #
      # @return [Hash]
      #
      def summary
        {
          ifc_version: ifc_version,
          entity_count: entity_count,
          geometry_count: geometry_count,
          total_area: total_area,
          total_volume: total_volume,
          property_set_count: property_sets.size,
          material_count: material_list.size,
          building_storey_count: building_storeys.size,
          space_count: spaces.size,
          complexity: complexity_score,
          duplicate: duplicate?,
          validation_passed: validation_passed?,
          warnings_count: validation_warnings.size
        }
      end

      ##
      # Export metadata as JSON
      #
      # @return [Hash]
      #
      def as_json(options = {})
        super(options).merge(
          'summary' => summary,
          'has_duplicates' => duplicate?,
          'validation_passed' => validation_passed?
        )
      end

      private

      def extract_elements_by_type(type_name)
        result = []
        traverse_spatial_structure(spatial_structure, type_name, result)
        result
      end

      def traverse_spatial_structure(node, type_name, result)
        return unless node.is_a?(Hash)

        if node['type'] == type_name
          result << node
        end

        if node['children'].is_a?(Array)
          node['children'].each do |child|
            traverse_spatial_structure(child, type_name, result)
          end
        end
      end
    end
  end
end
