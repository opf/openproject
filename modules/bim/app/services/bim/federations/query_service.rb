# frozen_string_literal: true

module Bim
  module Federations
    class QueryService
      def initialize(federation)
        @federation = federation
      end

      # Search for elements across all models in the federation
      # @param query [String] Search term (element name, type, GUID)
      # @param options [Hash] Search options (type_filter, discipline_filter)
      # @return [Array<Hash>] Matching elements with model context
      def search_elements(query, options = {})
        results = []

        models = filter_models_by_options(options)

        models.each do |fm|
          ifc_model = fm.ifc_model
          metadata = ifc_model.ifc_model_metadata
          next unless metadata

          element_matches = search_in_model(metadata, query, options)
          element_matches.each do |element|
            results << enrich_element_data(element, fm, ifc_model)
          end
        end

        results
      end

      # Find elements within a spatial zone across all models
      # @param zone [Hash] Bounding box { min: [x,y,z], max: [x,y,z] }
      # @param options [Hash] Filter options
      # @return [Array<Hash>] Elements within the zone
      def spatial_query(zone, options = {})
        results = []

        models = filter_models_by_options(options)

        models.each do |fm|
          ifc_model = fm.ifc_model
          metadata = ifc_model.ifc_model_metadata
          next unless metadata

          elements_in_zone = find_elements_in_zone(metadata, zone, fm.transform)
          elements_in_zone.each do |element|
            results << enrich_element_data(element, fm, ifc_model)
          end
        end

        results
      end

      # Aggregate properties across all models
      # @param property_name [String] Name of property to aggregate
      # @param options [Hash] Aggregation options (type_filter, discipline_filter)
      # @return [Hash] Aggregated statistics
      def aggregate_property(property_name, options = {})
        values = []
        models = filter_models_by_options(options)

        models.each do |fm|
          ifc_model = fm.ifc_model
          metadata = ifc_model.ifc_model_metadata
          next unless metadata

          model_values = extract_property_values(metadata, property_name)
          values.concat(model_values)
        end

        calculate_statistics(values, property_name)
      end

      # Count elements by type across all models
      # @return [Hash] Element type counts
      def element_type_distribution
        distribution = Hash.new(0)

        @federation.federation_models.includes(:ifc_model).each do |fm|
          metadata = fm.ifc_model.ifc_model_metadata
          next unless metadata

          element_index = metadata.element_index || {}
          element_index.each_value do |element|
            type = element['type'] || 'Unknown'
            distribution[type] += 1
          end
        end

        distribution.sort_by { |_, count| -count }.to_h
      end

      private

      def filter_models_by_options(options)
        models = @federation.federation_models.includes(:ifc_model)

        if options[:discipline_filter]
          models = models.where(discipline: options[:discipline_filter])
        end

        if options[:visible_only]
          models = models.visible
        end

        models
      end

      def search_in_model(metadata, query, options)
        element_index = metadata.element_index || {}
        matches = []

        element_index.each do |guid, element|
          # Match by type filter if specified
          if options[:type_filter]
            next unless element['type'] == options[:type_filter]
          end

          # Match by query string (case-insensitive)
          query_lower = query.to_s.downcase
          if guid.downcase.include?(query_lower) ||
             element['name']&.downcase&.include?(query_lower) ||
             element['type']&.downcase&.include?(query_lower)
            matches << element.merge(guid: guid)
          end
        end

        matches
      end

      def find_elements_in_zone(metadata, zone, transform)
        element_index = metadata.element_index || {}
        matches = []

        element_index.each do |guid, element|
          geometry = element['geometry']
          next unless geometry

          # Get element bounding box
          bbox = geometry['bounding_box']
          next unless bbox

          # Apply federation model transform
          transformed_bbox = apply_transform_to_bbox(bbox, transform)

          # Check if bounding box intersects with zone
          if bbox_intersects?(transformed_bbox, zone)
            matches << element.merge(guid: guid)
          end
        end

        matches
      end

      def apply_transform_to_bbox(bbox, transform)
        return bbox unless transform

        translation = transform['translation'] || [0, 0, 0]

        {
          'min' => [
            bbox['min'][0] + translation[0],
            bbox['min'][1] + translation[1],
            bbox['min'][2] + translation[2]
          ],
          'max' => [
            bbox['max'][0] + translation[0],
            bbox['max'][1] + translation[1],
            bbox['max'][2] + translation[2]
          ]
        }
      end

      def bbox_intersects?(bbox1, bbox2)
        # Check for overlap in all three dimensions
        x_overlap = bbox1['max'][0] >= bbox2[:min][0] && bbox1['min'][0] <= bbox2[:max][0]
        y_overlap = bbox1['max'][1] >= bbox2[:min][1] && bbox1['min'][1] <= bbox2[:max][1]
        z_overlap = bbox1['max'][2] >= bbox2[:min][2] && bbox1['min'][2] <= bbox2[:max][2]

        x_overlap && y_overlap && z_overlap
      end

      def extract_property_values(metadata, property_name)
        values = []
        element_index = metadata.element_index || {}

        element_index.each_value do |element|
          properties = element['properties'] || {}
          if properties.key?(property_name)
            value = properties[property_name]
            values << value if value.is_a?(Numeric)
          end
        end

        values
      end

      def calculate_statistics(values, property_name)
        return { property: property_name, count: 0 } if values.empty?

        {
          property: property_name,
          count: values.size,
          sum: values.sum,
          average: values.sum.to_f / values.size,
          min: values.min,
          max: values.max,
          median: calculate_median(values)
        }
      end

      def calculate_median(values)
        sorted = values.sort
        len = sorted.length
        (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
      end

      def enrich_element_data(element, federation_model, ifc_model)
        element.merge(
          model_id: ifc_model.id,
          model_name: ifc_model.title,
          discipline: federation_model.discipline,
          federation_model_id: federation_model.id
        )
      end
    end
  end
end
