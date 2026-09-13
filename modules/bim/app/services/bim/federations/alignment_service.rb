# frozen_string_literal: true

module Bim
  module Federations
    class AlignmentService
      def initialize(federation)
        @federation = federation
        @transformations = {}
      end

      def call
        # Find reference points (grids, survey points) across all models
        reference_data = find_reference_points

        # Calculate transformations to align all models
        calculate_transformations(reference_data)

        # Apply transformations to federation models
        apply_transformations

        ServiceResult.success(result: @transformations)
      rescue StandardError => e
        ServiceResult.failure(errors: "Alignment failed: #{e.message}")
      end

      private

      def find_reference_points
        @federation.federation_models.includes(:ifc_model).map do |fm|
          {
            federation_model: fm,
            grids: extract_grids(fm.ifc_model),
            site: extract_site(fm.ifc_model),
            extent: extract_extent(fm.ifc_model)
          }
        end
      end

      def extract_grids(ifc_model)
        # Extract IfcGrid elements from metadata
        metadata = ifc_model.ifc_model_metadata
        return [] unless metadata

        element_index = metadata.element_index || {}
        grids = element_index.select { |_, v| v['type'] == 'IfcGrid' }

        grids.map do |guid, data|
          {
            guid: guid,
            name: data['name'],
            position: data.dig('geometry', 'position') || [0, 0, 0]
          }
        end
      end

      def extract_site(ifc_model)
        # Extract IfcSite with geographic coordinates
        metadata = ifc_model.ifc_model_metadata
        return nil unless metadata

        spatial = metadata.spatial_structure || {}
        site_data = spatial['IfcSite']

        return nil unless site_data

        {
          name: site_data['name'],
          latitude: site_data['RefLatitude'],
          longitude: site_data['RefLongitude'],
          elevation: site_data['RefElevation'] || 0
        }
      end

      def extract_extent(ifc_model)
        metadata = ifc_model.ifc_model_metadata
        return nil unless metadata

        spatial = metadata.spatial_structure || {}
        spatial['extent']
      end

      def calculate_transformations(reference_data)
        # Use the first model as the base (no transformation)
        base_model = reference_data.first
        return if base_model.nil?

        @transformations[base_model[:federation_model].id] = default_transform

        # For other models, try to align using grids or site coordinates
        reference_data[1..].each do |data|
          fm = data[:federation_model]
          transform = calculate_transform_for_model(data, base_model)
          @transformations[fm.id] = transform
        end
      end

      def calculate_transform_for_model(model_data, base_model_data)
        # Try grid-based alignment first
        transform = align_by_grids(model_data[:grids], base_model_data[:grids])
        return transform if transform

        # Fallback: align by site coordinates
        transform = align_by_site(model_data[:site], base_model_data[:site])
        return transform if transform

        # Last resort: align by extent (center models)
        align_by_extent(model_data[:extent], base_model_data[:extent])
      end

      def align_by_grids(model_grids, base_grids)
        return nil if model_grids.empty? || base_grids.empty?

        # Find matching grids by name
        matching_pairs = find_matching_grids(model_grids, base_grids)
        return nil if matching_pairs.empty?

        # Calculate translation based on first matching grid pair
        base_pos = matching_pairs.first[:base_position]
        model_pos = matching_pairs.first[:model_position]

        {
          translation: [
            base_pos[0] - model_pos[0],
            base_pos[1] - model_pos[1],
            base_pos[2] - model_pos[2]
          ],
          rotation: [0, 0, 0],
          scale: [1, 1, 1]
        }
      end

      def find_matching_grids(model_grids, base_grids)
        matches = []

        model_grids.each do |mg|
          base_grids.each do |bg|
            if mg[:name] == bg[:name]
              matches << {
                name: mg[:name],
                model_position: mg[:position],
                base_position: bg[:position]
              }
            end
          end
        end

        matches
      end

      def align_by_site(model_site, base_site)
        return nil unless model_site && base_site

        # Simple elevation-based alignment
        # Full implementation would convert lat/long to local coordinates
        elevation_diff = base_site[:elevation].to_f - model_site[:elevation].to_f

        {
          translation: [0, 0, elevation_diff],
          rotation: [0, 0, 0],
          scale: [1, 1, 1]
        }
      end

      def align_by_extent(model_extent, base_extent)
        return default_transform unless model_extent && base_extent

        # Align centers
        base_center = calculate_center(base_extent)
        model_center = calculate_center(model_extent)

        {
          translation: [
            base_center[0] - model_center[0],
            base_center[1] - model_center[1],
            0 # Don't adjust Z to preserve floor levels
          ],
          rotation: [0, 0, 0],
          scale: [1, 1, 1]
        }
      end

      def calculate_center(extent)
        [
          (extent['min'][0] + extent['max'][0]) / 2.0,
          (extent['min'][1] + extent['max'][1]) / 2.0,
          (extent['min'][2] + extent['max'][2]) / 2.0
        ]
      end

      def apply_transformations
        @transformations.each do |fm_id, transform|
          federation_model = @federation.federation_models.find(fm_id)
          federation_model.update!(transform: transform)
        end
      end

      def default_transform
        {
          translation: [0, 0, 0],
          rotation: [0, 0, 0],
          scale: [1, 1, 1]
        }
      end
    end
  end
end
