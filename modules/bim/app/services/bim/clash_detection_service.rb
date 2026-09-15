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
  class ClashDetectionService
    attr_reader :ifc_model, :options

    DEFAULT_OPTIONS = {
      clearance_distance: 50.0,      # mm
      soft_clash_distance: 100.0,    # mm
      min_overlap_volume: 0.001,     # cubic units
      detect_hard_clashes: true,
      detect_soft_clashes: true,
      detect_clearance_clashes: false,
      element_type_filters: nil,     # nil = all types
      element_tag_filters: nil,      # nil = all tags
      severity_rules: {}             # Custom severity assignment rules
    }.freeze

    def initialize(ifc_model:, options: {})
      @ifc_model = ifc_model
      @options = DEFAULT_OPTIONS.merge(options)
      @detection_run_id = generate_run_id
    end

    # Main detection method - finds all clashes in the model
    def detect_all_clashes
      return error_result('IFC model has no metadata') unless ifc_model.metadata

      elements = filtered_elements
      return success_result([]) if elements.size < 2

      clashes = []
      element_pairs = generate_element_pairs(elements)

      element_pairs.each do |elem_a_id, elem_b_id|
        clash = detect_clash_between(elem_a_id, elem_b_id)
        clashes << clash if clash
      end

      # Save all clashes to database
      saved_clashes = save_clashes(clashes)

      success_result(saved_clashes)
    end

    # Detect clashes for a specific element against all others
    def detect_clashes_for_element(element_id)
      return error_result('Element not found') unless element_exists?(element_id)

      elements = filtered_elements.reject { |id| id == element_id }
      clashes = []

      elements.each do |other_id|
        clash = detect_clash_between(element_id, other_id)
        clashes << clash if clash
      end

      saved_clashes = save_clashes(clashes)
      success_result(saved_clashes)
    end

    # Detect clash between two specific elements
    def detect_clash_between(element_a_id, element_b_id)
      elem_a = get_element_data(element_a_id)
      elem_b = get_element_data(element_b_id)

      return nil unless elem_a && elem_b

      # Get bounding boxes
      bbox_a = extract_bounding_box(elem_a)
      bbox_b = extract_bounding_box(elem_b)

      return nil unless bbox_a && bbox_b

      # Check for intersection
      if bounding_boxes_intersect?(bbox_a, bbox_b)
        detect_hard_clash(element_a_id, element_b_id, elem_a, elem_b, bbox_a, bbox_b)
      elsif options[:detect_soft_clashes] || options[:detect_clearance_clashes]
        detect_proximity_clash(element_a_id, element_b_id, elem_a, elem_b, bbox_a, bbox_b)
      end
    end

    # Re-detect clashes after model update
    def refresh_clashes
      # Delete old clashes from this model
      old_clash_count = Clash.where(ifc_model: ifc_model).destroy_all.size

      # Detect new clashes
      result = detect_all_clashes

      result[:old_clash_count] = old_clash_count if result.success?
      result
    end

    # Get statistics about detected clashes
    def clash_statistics
      clashes = Clash.where(ifc_model: ifc_model)

      {
        total: clashes.count,
        by_type: clashes.group(:clash_type).count,
        by_severity: clashes.group(:severity).count,
        by_status: clashes.group(:status).count,
        unresolved: clashes.unresolved.count,
        critical: clashes.where(severity: :critical).count,
        recent_24h: clashes.where('detected_at > ?', 24.hours.ago).count
      }
    end

    private

    def generate_run_id
      "clash_run_#{Time.current.to_i}_#{SecureRandom.hex(4)}"
    end

    def filtered_elements
      elements = ifc_model.metadata['elements'] || {}
      element_ids = elements.keys

      # Filter by element type if specified
      if options[:element_type_filters].present?
        element_ids = element_ids.select do |id|
          elem_type = elements[id]&.dig('properties', 'type')
          options[:element_type_filters].include?(elem_type)
        end
      end

      # Filter by tags if specified
      if options[:element_tag_filters].present?
        element_ids = element_ids.select do |id|
          elem_tags = elements[id]&.dig('properties', 'tags') || []
          (options[:element_tag_filters] & elem_tags).any?
        end
      end

      element_ids
    end

    def generate_element_pairs(elements)
      pairs = []
      elements.combination(2) { |pair| pairs << pair }
      pairs
    end

    def element_exists?(element_id)
      ifc_model.metadata&.dig('elements', element_id).present?
    end

    def get_element_data(element_id)
      ifc_model.metadata&.dig('elements', element_id)
    end

    def extract_bounding_box(element_data)
      bbox = element_data&.dig('geometry', 'bbox')
      return nil unless bbox && bbox.is_a?(Array) && bbox.size == 6

      {
        min: bbox[0..2],  # [xmin, ymin, zmin]
        max: bbox[3..5]   # [xmax, ymax, zmax]
      }
    end

    def bounding_boxes_intersect?(bbox_a, bbox_b)
      # Check if two AABBs (Axis-Aligned Bounding Boxes) intersect
      # Boxes intersect if they overlap on all three axes

      x_overlap = bbox_a[:min][0] <= bbox_b[:max][0] && bbox_a[:max][0] >= bbox_b[:min][0]
      y_overlap = bbox_a[:min][1] <= bbox_b[:max][1] && bbox_a[:max][1] >= bbox_b[:min][1]
      z_overlap = bbox_a[:min][2] <= bbox_b[:max][2] && bbox_a[:max][2] >= bbox_b[:min][2]

      x_overlap && y_overlap && z_overlap
    end

    def calculate_overlap_volume(bbox_a, bbox_b)
      return 0 unless bounding_boxes_intersect?(bbox_a, bbox_b)

      # Calculate intersection box
      x_overlap = [bbox_a[:max][0], bbox_b[:max][0]].min - [bbox_a[:min][0], bbox_b[:min][0]].max
      y_overlap = [bbox_a[:max][1], bbox_b[:max][1]].min - [bbox_a[:min][1], bbox_b[:min][1]].max
      z_overlap = [bbox_a[:max][2], bbox_b[:max][2]].min - [bbox_a[:min][2], bbox_b[:min][2]].max

      x_overlap * y_overlap * z_overlap
    end

    def calculate_min_distance(bbox_a, bbox_b)
      # Calculate minimum distance between two bounding boxes
      # If they intersect, distance is negative (overlap amount)

      if bounding_boxes_intersect?(bbox_a, bbox_b)
        # Boxes overlap - calculate penetration depth
        x_pen = [bbox_a[:max][0], bbox_b[:max][0]].min - [bbox_a[:min][0], bbox_b[:min][0]].max
        y_pen = [bbox_a[:max][1], bbox_b[:max][1]].min - [bbox_a[:min][1], bbox_b[:min][1]].max
        z_pen = [bbox_a[:max][2], bbox_b[:max][2]].min - [bbox_a[:min][2], bbox_b[:min][2]].max

        -[x_pen, y_pen, z_pen].min # Negative to indicate overlap
      else
        # Boxes don't overlap - calculate gap distance
        x_gap = [
          (bbox_a[:min][0] - bbox_b[:max][0]).abs,
          (bbox_b[:min][0] - bbox_a[:max][0]).abs
        ].min

        y_gap = [
          (bbox_a[:min][1] - bbox_b[:max][1]).abs,
          (bbox_b[:min][1] - bbox_a[:max][1]).abs
        ].min

        z_gap = [
          (bbox_a[:min][2] - bbox_b[:max][2]).abs,
          (bbox_b[:min][2] - bbox_a[:max][2]).abs
        ].min

        Math.sqrt(x_gap**2 + y_gap**2 + z_gap**2)
      end
    end

    def calculate_clash_point(bbox_a, bbox_b)
      # Calculate approximate clash point (center of intersection)
      if bounding_boxes_intersect?(bbox_a, bbox_b)
        x = ([bbox_a[:max][0], bbox_b[:max][0]].min + [bbox_a[:min][0], bbox_b[:min][0]].max) / 2.0
        y = ([bbox_a[:max][1], bbox_b[:max][1]].min + [bbox_a[:min][1], bbox_b[:min][1]].max) / 2.0
        z = ([bbox_a[:max][2], bbox_b[:max][2]].min + [bbox_a[:min][2], bbox_b[:min][2]].max) / 2.0

        { x: x, y: y, z: z }
      else
        # If no intersection, use midpoint between box centers
        center_a = bbox_center(bbox_a)
        center_b = bbox_center(bbox_b)

        {
          x: (center_a[0] + center_b[0]) / 2.0,
          y: (center_a[1] + center_b[1]) / 2.0,
          z: (center_a[2] + center_b[2]) / 2.0
        }
      end
    end

    def bbox_center(bbox)
      [
        (bbox[:min][0] + bbox[:max][0]) / 2.0,
        (bbox[:min][1] + bbox[:max][1]) / 2.0,
        (bbox[:min][2] + bbox[:max][2]) / 2.0
      ]
    end

    def detect_hard_clash(elem_a_id, elem_b_id, elem_a, elem_b, bbox_a, bbox_b)
      return nil unless options[:detect_hard_clashes]

      overlap_volume = calculate_overlap_volume(bbox_a, bbox_b)
      return nil if overlap_volume < options[:min_overlap_volume]

      distance = calculate_min_distance(bbox_a, bbox_b)
      clash_point = calculate_clash_point(bbox_a, bbox_b)
      severity = determine_severity(:hard, overlap_volume, elem_a, elem_b)

      {
        element_a_id: elem_a_id,
        element_b_id: elem_b_id,
        clash_type: :hard,
        severity: severity,
        status: :new,
        distance: distance,
        overlap_volume: overlap_volume,
        clash_point: clash_point,
        detected_at: Time.current,
        detection_run_id: @detection_run_id,
        detection_params: options
      }
    end

    def detect_proximity_clash(elem_a_id, elem_b_id, elem_a, elem_b, bbox_a, bbox_b)
      distance = calculate_min_distance(bbox_a, bbox_b)

      # Check for soft clash (within soft clash distance)
      if options[:detect_soft_clashes] && distance < options[:soft_clash_distance] && distance >= 0
        return create_proximity_clash(elem_a_id, elem_b_id, elem_a, elem_b, :soft, distance)
      end

      # Check for clearance clash (within clearance distance)
      if options[:detect_clearance_clashes] && distance < options[:clearance_distance] && distance >= 0
        return create_proximity_clash(elem_a_id, elem_b_id, elem_a, elem_b, :clearance, distance)
      end

      nil
    end

    def create_proximity_clash(elem_a_id, elem_b_id, elem_a, elem_b, type, distance)
      clash_point = calculate_clash_point(
        extract_bounding_box(elem_a),
        extract_bounding_box(elem_b)
      )

      severity = determine_severity(type, distance, elem_a, elem_b)

      {
        element_a_id: elem_a_id,
        element_b_id: elem_b_id,
        clash_type: type,
        severity: severity,
        status: :new,
        distance: distance,
        overlap_volume: nil,
        clash_point: clash_point,
        detected_at: Time.current,
        detection_run_id: @detection_run_id,
        detection_params: options
      }
    end

    def determine_severity(clash_type, metric_value, elem_a, elem_b)
      # Custom severity rules if provided
      if options[:severity_rules].present?
        custom_severity = apply_custom_severity_rules(clash_type, metric_value, elem_a, elem_b)
        return custom_severity if custom_severity
      end

      # Default severity rules
      case clash_type
      when :hard
        # Hard clashes: severity based on overlap volume
        if metric_value > 1000  # Large overlap
          :critical
        elsif metric_value > 100
          :major
        else
          :minor
        end
      when :soft, :clearance
        # Soft/clearance clashes: severity based on distance
        if metric_value < 10  # Very close
          :major
        elsif metric_value < 50
          :minor
        else
          :minor
        end
      else
        :minor
      end
    end

    def apply_custom_severity_rules(clash_type, metric_value, elem_a, elem_b)
      # Allow custom severity assignment based on element types or other criteria
      rules = options[:severity_rules][clash_type]
      return nil unless rules

      rules.each do |rule|
        if rule_matches?(rule, elem_a, elem_b, metric_value)
          return rule[:severity]
        end
      end

      nil
    end

    def rule_matches?(rule, elem_a, elem_b, metric_value)
      # Check if rule conditions match
      # Rules can specify element types, properties, thresholds, etc.
      true # Simplified for now
    end

    def save_clashes(clash_data_array)
      clashes = []

      clash_data_array.each do |clash_data|
        # Check if clash already exists
        existing = Clash.find_by(
          ifc_model: ifc_model,
          element_a_id: clash_data[:element_a_id],
          element_b_id: clash_data[:element_b_id]
        )

        if existing
          # Update existing clash
          existing.update(clash_data.except(:element_a_id, :element_b_id))
          clashes << existing
        else
          # Create new clash
          clash = Clash.create(clash_data.merge(ifc_model: ifc_model))
          clashes << clash if clash.persisted?
        end
      end

      clashes
    end

    def success_result(data)
      ServiceResult.success(result: {
        clashes: data,
        count: data.size,
        detection_run_id: @detection_run_id,
        detected_at: Time.current
      })
    end

    def error_result(message)
      ServiceResult.failure(message: message)
    end
  end
end
