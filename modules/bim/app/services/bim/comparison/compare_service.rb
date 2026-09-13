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
  module Comparison
    ##
    # Service for comparing two IFC models and detecting changes
    #
    # Detects:
    # - Added elements (in model2, not in model1)
    # - Deleted elements (in model1, not in model2)
    # - Modified elements (changed geometry or properties)
    # - Unchanged elements (identical in both models)
    #
    # Example:
    #   service = Bim::Comparison::CompareService.new(
    #     model1: old_model,
    #     model2: new_model,
    #     options: { detect_geometry_changes: true }
    #   )
    #   result = service.call
    #
    class CompareService
      attr_reader :model1, :model2, :options

      ##
      # Initialize comparison service
      #
      # @param model1 [Bim::IfcModels::IfcModel] First model (baseline/old)
      # @param model2 [Bim::IfcModels::IfcModel] Second model (current/new)
      # @param options [Hash] Comparison options
      #
      def initialize(model1:, model2:, options: {})
        @model1 = model1
        @model2 = model2
        @options = default_options.merge(options)
      end

      ##
      # Execute comparison
      #
      # @return [ServiceResult]
      #
      def call
        start_time = Time.current

        validate_models!

        metadata1 = load_metadata(model1)
        metadata2 = load_metadata(model2)

        changes = detect_changes(metadata1, metadata2)

        # Create comparison record
        comparison = Bim::ModelComparison.create!(
          model1: model1,
          model2: model2,
          comparison_type: options[:comparison_type] || :version,
          added_count: changes[:added].size,
          deleted_count: changes[:deleted].size,
          modified_count: changes[:modified].size,
          unchanged_count: changes[:unchanged].size,
          changes_data: changes,
          statistics: calculate_statistics(changes, metadata1, metadata2),
          comparison_options: options,
          created_by: options[:user]
        )

        execution_time = Time.current - start_time
        comparison.complete!(time: execution_time)

        ServiceResult.success(result: comparison)
      rescue StandardError => e
        ServiceResult.failure(errors: [e.message])
      end

      private

      def default_options
        {
          detect_geometry_changes: true,
          detect_property_changes: true,
          detect_type_changes: true,
          ignore_properties: [],  # Properties to ignore in comparison
          comparison_type: :version
        }
      end

      def validate_models!
        raise ArgumentError, 'model1 is required' unless model1
        raise ArgumentError, 'model2 is required' unless model2
        raise ArgumentError, 'Cannot compare model with itself' if model1.id == model2.id
        raise ArgumentError, 'Models must be in same project' if model1.project_id != model2.project_id
      end

      def load_metadata(model)
        model.metadata&.dig('elements') || {}
      end

      def detect_changes(metadata1, metadata2)
        elem_ids1 = Set.new(metadata1.keys)
        elem_ids2 = Set.new(metadata2.keys)

        added_ids = elem_ids2 - elem_ids1
        deleted_ids = elem_ids1 - elem_ids2
        common_ids = elem_ids1 & elem_ids2

        added = build_added_elements(added_ids, metadata2)
        deleted = build_deleted_elements(deleted_ids, metadata1)
        modified, unchanged = detect_modifications(common_ids, metadata1, metadata2)

        {
          added: added,
          deleted: deleted,
          modified: modified,
          unchanged: unchanged
        }
      end

      def build_added_elements(element_ids, metadata)
        element_ids.map do |elem_id|
          {
            element_id: elem_id,
            element: metadata[elem_id]
          }
        end
      end

      def build_deleted_elements(element_ids, metadata)
        element_ids.map do |elem_id|
          {
            element_id: elem_id,
            element: metadata[elem_id]
          }
        end
      end

      def detect_modifications(common_ids, metadata1, metadata2)
        modified = []
        unchanged = []

        common_ids.each do |elem_id|
          elem1 = metadata1[elem_id]
          elem2 = metadata2[elem_id]

          changes = detect_element_changes(elem1, elem2)

          if changes.any?
            modified << {
              element_id: elem_id,
              element_before: elem1,
              element_after: elem2,
              changes: changes
            }
          else
            unchanged << {
              element_id: elem_id,
              element: elem1
            }
          end
        end

        [modified, unchanged]
      end

      def detect_element_changes(elem1, elem2)
        changes = []

        # Detect geometry changes
        if options[:detect_geometry_changes]
          geometry_changes = detect_geometry_changes(elem1, elem2)
          changes.concat(geometry_changes)
        end

        # Detect property changes
        if options[:detect_property_changes]
          property_changes = detect_property_changes(elem1, elem2)
          changes.concat(property_changes)
        end

        # Detect type changes
        if options[:detect_type_changes]
          type_changes = detect_type_changes(elem1, elem2)
          changes.concat(type_changes)
        end

        changes
      end

      def detect_geometry_changes(elem1, elem2)
        changes = []

        hash1 = elem1.dig('geometry', 'hash')
        hash2 = elem2.dig('geometry', 'hash')

        if hash1 != hash2
          changes << {
            type: 'geometry',
            description: 'Geometry changed',
            old_value: elem1['geometry'],
            new_value: elem2['geometry'],
            details: analyze_geometry_change(elem1['geometry'], elem2['geometry'])
          }
        end

        changes
      end

      def analyze_geometry_change(geom1, geom2)
        details = {}

        # Check bounding box changes
        bbox1 = geom1&.dig('boundingBox')
        bbox2 = geom2&.dig('boundingBox')

        if bbox1 && bbox2
          # Check for position change
          min1 = bbox1['min']
          min2 = bbox2['min']
          if min1 != min2
            details[:position_changed] = true
            details[:position_delta] = calculate_position_delta(min1, min2)
          end

          # Check for size change
          size1 = calculate_bbox_size(bbox1)
          size2 = calculate_bbox_size(bbox2)
          if size1 != size2
            details[:size_changed] = true
            details[:size_delta] = {
              width: size2[:width] - size1[:width],
              height: size2[:height] - size1[:height],
              depth: size2[:depth] - size1[:depth]
            }
          end
        end

        details
      end

      def calculate_bbox_size(bbox)
        min = bbox['min']
        max = bbox['max']

        {
          width: max[0] - min[0],
          height: max[1] - min[1],
          depth: max[2] - min[2]
        }
      end

      def calculate_position_delta(min1, min2)
        {
          x: min2[0] - min1[0],
          y: min2[1] - min1[1],
          z: min2[2] - min1[2]
        }
      end

      def detect_property_changes(elem1, elem2)
        changes = []

        props1 = elem1['properties'] || {}
        props2 = elem2['properties'] || {}

        all_props = (props1.keys | props2.keys) - options[:ignore_properties]

        all_props.each do |prop_key|
          old_value = props1[prop_key]
          new_value = props2[prop_key]

          next if old_value == new_value

          changes << {
            type: 'property',
            description: "Property '#{prop_key}' changed",
            property: prop_key,
            old_value: old_value,
            new_value: new_value
          }
        end

        changes
      end

      def detect_type_changes(elem1, elem2)
        changes = []

        type1 = elem1.dig('properties', 'type')
        type2 = elem2.dig('properties', 'type')

        if type1 != type2
          changes << {
            type: 'element_type',
            description: 'Element type changed',
            old_value: type1,
            new_value: type2
          }
        end

        changes
      end

      def calculate_statistics(changes, metadata1, metadata2)
        stats = {
          total_elements_model1: metadata1.size,
          total_elements_model2: metadata2.size,
          change_percentage: 0.0,
          geometry_changes: 0,
          property_changes: 0,
          type_changes: 0,
          by_type: {}
        }

        # Calculate overall change percentage
        total_elements = [metadata1.size, metadata2.size].max
        total_changes = changes[:added].size + changes[:deleted].size + changes[:modified].size
        stats[:change_percentage] = total_elements.zero? ? 0.0 : (total_changes.to_f / total_elements * 100).round(2)

        # Count change types
        changes[:modified].each do |mod|
          mod[:changes].each do |change|
            case change[:type]
            when 'geometry'
              stats[:geometry_changes] += 1
            when 'property'
              stats[:property_changes] += 1
            when 'element_type'
              stats[:type_changes] += 1
            end
          end
        end

        # Group by element type
        type_stats = Hash.new { |h, k| h[k] = { added: 0, deleted: 0, modified: 0 } }

        changes[:added].each do |elem|
          type = elem.dig(:element, 'properties', 'type') || 'Unknown'
          type_stats[type][:added] += 1
        end

        changes[:deleted].each do |elem|
          type = elem.dig(:element, 'properties', 'type') || 'Unknown'
          type_stats[type][:deleted] += 1
        end

        changes[:modified].each do |elem|
          type = elem.dig(:element_after, 'properties', 'type') || 'Unknown'
          type_stats[type][:modified] += 1
        end

        stats[:by_type] = type_stats

        stats
      end
    end
  end
end
