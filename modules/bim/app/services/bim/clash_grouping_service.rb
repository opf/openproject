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
  ##
  # Service for grouping and clustering related clashes
  #
  # Provides intelligent grouping of clashes by:
  # - Element involvement (same element in multiple clashes)
  # - Spatial proximity (clashes in same area)
  # - Element type patterns (same types involved)
  # - Severity patterns
  #
  # Example:
  #   service = Bim::ClashGroupingService.new(ifc_model: model)
  #   result = service.group_by_element
  #
  class ClashGroupingService
    attr_reader :ifc_model

    def initialize(ifc_model:)
      @ifc_model = ifc_model
    end

    ##
    # Group clashes by elements involved
    #
    # Identifies elements that appear in multiple clashes
    # Useful for finding problematic elements
    #
    # @param min_clash_count [Integer] Minimum clashes to include element
    # @return [ServiceResult] Grouped clashes
    #
    def group_by_element(min_clash_count: 2)
      clashes = Bim::Clash.where(ifc_model: ifc_model).active_clashes

      element_groups = Hash.new { |h, k| h[k] = [] }

      # Build element -> clashes mapping
      clashes.each do |clash|
        element_groups[clash.element_a_id] << clash
        element_groups[clash.element_b_id] << clash
      end

      # Filter by minimum count and format results
      groups = element_groups
                 .select { |_element_id, clash_list| clash_list.size >= min_clash_count }
                 .map do |element_id, clash_list|
        {
          element_id: element_id,
          element_name: element_name_from_metadata(element_id),
          clash_count: clash_list.size,
          clashes: clash_list.uniq,
          severity_breakdown: severity_breakdown(clash_list),
          type_breakdown: type_breakdown(clash_list)
        }
      end
                 .sort_by { |g| -g[:clash_count] }

      ServiceResult.success(
        result: {
          total_groups: groups.size,
          total_elements_involved: element_groups.keys.size,
          groups: groups,
          summary: {
            most_problematic_element: groups.first,
            average_clashes_per_element: (clashes.count.to_f / element_groups.keys.size).round(2)
          }
        }
      )
    end

    ##
    # Group clashes by spatial proximity
    #
    # Clusters clashes that occur in the same spatial area
    # Uses clash_point coordinates for clustering
    #
    # @param distance_threshold [Float] Maximum distance (in model units) for grouping
    # @return [ServiceResult] Spatial clusters
    #
    def group_by_spatial_proximity(distance_threshold: 5000.0)
      clashes = Bim::Clash
                  .where(ifc_model: ifc_model)
                  .active_clashes
                  .where.not(clash_point: nil)

      return ServiceResult.failure(errors: ['No clashes with spatial data']) if clashes.empty?

      # Simple spatial clustering using distance threshold
      clusters = []
      unassigned = clashes.to_a

      while unassigned.any?
        seed = unassigned.shift
        cluster = [seed]

        # Find all clashes within threshold of seed
        unassigned.reject! do |clash|
          if within_distance?(seed.clash_point, clash.clash_point, distance_threshold)
            cluster << clash
            true
          else
            false
          end
        end

        clusters << cluster
      end

      formatted_clusters = clusters.map.with_index do |cluster_clashes, index|
        {
          cluster_id: index + 1,
          clash_count: cluster_clashes.size,
          clashes: cluster_clashes,
          centroid: calculate_centroid(cluster_clashes.map(&:clash_point)),
          severity_breakdown: severity_breakdown(cluster_clashes),
          bounding_box: calculate_bounding_box(cluster_clashes.map(&:clash_point))
        }
      end.sort_by { |c| -c[:clash_count] }

      ServiceResult.success(
        result: {
          total_clusters: formatted_clusters.size,
          total_clashes_clustered: clashes.count,
          distance_threshold: distance_threshold,
          clusters: formatted_clusters,
          summary: {
            largest_cluster: formatted_clusters.first,
            average_cluster_size: (clashes.count.to_f / formatted_clusters.size).round(2)
          }
        }
      )
    end

    ##
    # Group clashes by element type patterns
    #
    # Identifies common clash patterns between specific element types
    # E.g., "Walls vs Ducts", "Columns vs Beams"
    #
    # @return [ServiceResult] Type pattern groups
    #
    def group_by_type_pattern
      clashes = Bim::Clash.where(ifc_model: ifc_model).active_clashes
      type_pairs = Hash.new { |h, k| h[k] = [] }

      clashes.each do |clash|
        type_a = element_type_from_metadata(clash.element_a_id)
        type_b = element_type_from_metadata(clash.element_b_id)

        # Sort types to normalize key (A-B same as B-A)
        pair_key = [type_a, type_b].sort.join(' vs ')
        type_pairs[pair_key] << clash
      end

      groups = type_pairs.map do |pair_key, clash_list|
        types = pair_key.split(' vs ')
        {
          type_pair: pair_key,
          type_a: types[0],
          type_b: types[1],
          clash_count: clash_list.size,
          clashes: clash_list,
          severity_breakdown: severity_breakdown(clash_list),
          average_severity_score: average_severity_score(clash_list)
        }
      end.sort_by { |g| -g[:clash_count] }

      ServiceResult.success(
        result: {
          total_type_patterns: groups.size,
          groups: groups,
          summary: {
            most_common_pattern: groups.first,
            total_clashes: clashes.count
          }
        }
      )
    end

    ##
    # Group clashes by detection run
    #
    # Organizes clashes by when they were detected
    # Useful for tracking changes over time
    #
    # @return [ServiceResult] Run-based groups
    #
    def group_by_detection_run
      clashes = Bim::Clash.where(ifc_model: ifc_model)

      run_groups = clashes
                     .group(:detection_run_id)
                     .select('detection_run_id, COUNT(*) as clash_count, MIN(detected_at) as run_date')
                     .order('run_date DESC')

      formatted_groups = run_groups.map do |group|
        run_clashes = clashes.where(detection_run_id: group.detection_run_id)

        {
          detection_run_id: group.detection_run_id,
          run_date: group.run_date,
          clash_count: group.clash_count,
          clashes: run_clashes,
          severity_breakdown: severity_breakdown(run_clashes),
          status_breakdown: status_breakdown(run_clashes)
        }
      end

      ServiceResult.success(
        result: {
          total_runs: formatted_groups.size,
          groups: formatted_groups,
          summary: {
            latest_run: formatted_groups.first,
            total_clashes: clashes.count
          }
        }
      )
    end

    ##
    # Group clashes by spatial structure (building, storey, space)
    #
    # Organizes clashes by where they occur in the building hierarchy
    #
    # @param level [Symbol] :building, :storey, or :space
    # @return [ServiceResult] Spatial structure groups
    #
    def group_by_spatial_structure(level: :storey)
      clashes = Bim::Clash.where(ifc_model: ifc_model).active_clashes
      location_groups = Hash.new { |h, k| h[k] = [] }

      clashes.each do |clash|
        location = extract_spatial_location(clash.element_a_id, level)
        location_groups[location] << clash if location
      end

      groups = location_groups.map do |location, clash_list|
        {
          location: location,
          level: level,
          clash_count: clash_list.size,
          clashes: clash_list,
          severity_breakdown: severity_breakdown(clash_list),
          type_breakdown: type_breakdown(clash_list)
        }
      end.sort_by { |g| -g[:clash_count] }

      ServiceResult.success(
        result: {
          level: level,
          total_locations: groups.size,
          groups: groups,
          summary: {
            most_problematic_location: groups.first,
            total_clashes: clashes.count
          }
        }
      )
    end

    private

    ##
    # Calculate if two points are within distance threshold
    #
    def within_distance?(point1, point2, threshold)
      return false unless point1 && point2

      dx = point1['x'].to_f - point2['x'].to_f
      dy = point1['y'].to_f - point2['y'].to_f
      dz = point1['z'].to_f - point2['z'].to_f

      distance = Math.sqrt(dx**2 + dy**2 + dz**2)
      distance <= threshold
    end

    ##
    # Calculate centroid of clash points
    #
    def calculate_centroid(points)
      return nil if points.empty?

      sum_x = points.sum { |p| p['x'].to_f }
      sum_y = points.sum { |p| p['y'].to_f }
      sum_z = points.sum { |p| p['z'].to_f }
      count = points.size

      {
        x: (sum_x / count).round(2),
        y: (sum_y / count).round(2),
        z: (sum_z / count).round(2)
      }
    end

    ##
    # Calculate bounding box of clash points
    #
    def calculate_bounding_box(points)
      return nil if points.empty?

      xs = points.map { |p| p['x'].to_f }
      ys = points.map { |p| p['y'].to_f }
      zs = points.map { |p| p['z'].to_f }

      {
        min: { x: xs.min, y: ys.min, z: zs.min },
        max: { x: xs.max, y: ys.max, z: zs.max }
      }
    end

    ##
    # Get severity breakdown for clash list
    #
    def severity_breakdown(clash_list)
      clash_list.group_by(&:severity).transform_values(&:count)
    end

    ##
    # Get type breakdown for clash list
    #
    def type_breakdown(clash_list)
      clash_list.group_by(&:clash_type).transform_values(&:count)
    end

    ##
    # Get status breakdown for clash list
    #
    def status_breakdown(clash_list)
      clash_list.group_by(&:status).transform_values(&:count)
    end

    ##
    # Calculate average severity score
    #
    def average_severity_score(clash_list)
      return 0.0 if clash_list.empty?

      scores = clash_list.map(&:severity_score)
      (scores.sum.to_f / scores.size).round(2)
    end

    ##
    # Get element name from metadata
    #
    def element_name_from_metadata(element_id)
      element_data = ifc_model.metadata.dig('elements', element_id)
      element_data&.dig('properties', 'name') || element_id
    end

    ##
    # Get element type from metadata
    #
    def element_type_from_metadata(element_id)
      element_data = ifc_model.metadata.dig('elements', element_id)
      element_data&.dig('properties', 'type') || 'Unknown'
    end

    ##
    # Extract spatial location from element metadata
    #
    def extract_spatial_location(element_id, level)
      element_data = ifc_model.metadata.dig('elements', element_id)
      return nil unless element_data

      spatial_structure = element_data.dig('spatial_structure')
      return nil unless spatial_structure

      case level
      when :building
        spatial_structure['building']
      when :storey
        spatial_structure['storey']
      when :space
        spatial_structure['space']
      else
        nil
      end
    end
  end
end
