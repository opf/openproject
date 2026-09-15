# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

module Bim
  class Measurement < ApplicationRecord
    self.table_name = 'bim_measurements'

    MEASUREMENT_TYPES = %w[distance area volume angle elevation].freeze

    # Common units for each measurement type
    UNITS = {
      'distance' => %w[m cm mm ft in],
      'area' => %w[m² cm² mm² ft² in²],
      'volume' => %w[m³ cm³ mm³ ft³ in³],
      'angle' => %w[degrees radians],
      'elevation' => %w[m cm mm ft in]
    }.freeze

    belongs_to :ifc_model, class_name: 'Bim::IfcModels::IfcModel'
    belongs_to :user, optional: true

    validates :measurement_type, presence: true, inclusion: { in: MEASUREMENT_TYPES }
    validates :value, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :unit, presence: true
    validates :points, presence: true
    validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: 'must be a valid hex color' }, allow_nil: true
    validates :line_width,
              numericality: { greater_than: 0, less_than_or_equal_to: 10 },
              allow_nil: true

    validate :validate_points_for_measurement_type
    validate :validate_unit_for_measurement_type

    scope :visible, -> { where(visible: true) }
    scope :hidden, -> { where(visible: false) }
    scope :for_model, ->(model_id) { where(ifc_model_id: model_id) }
    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :by_type, ->(type) { where(measurement_type: type) }
    scope :distances, -> { where(measurement_type: 'distance') }
    scope :areas, -> { where(measurement_type: 'area') }
    scope :volumes, -> { where(measurement_type: 'volume') }
    scope :angles, -> { where(measurement_type: 'angle') }
    scope :elevations, -> { where(measurement_type: 'elevation') }

    # Calculate distance measurement from points
    def self.calculate_distance(points)
      return 0 if points.length < 2

      total_distance = 0
      (0...points.length - 1).each do |i|
        p1 = points[i]
        p2 = points[i + 1]
        total_distance += Math.sqrt(
          (p2[0] - p1[0])**2 +
          (p2[1] - p1[1])**2 +
          (p2[2] - p1[2])**2
        )
      end
      total_distance
    end

    # Calculate area from polygon points (simplified - uses triangulation)
    def self.calculate_area(points)
      return 0 if points.length < 3

      # Simple polygon area using shoelace formula (2D projection to XZ plane)
      area = 0
      n = points.length
      (0...n).each do |i|
        j = (i + 1) % n
        area += points[i][0] * points[j][2]
        area -= points[j][0] * points[i][2]
      end
      (area.abs / 2.0).round(4)
    end

    # Calculate volume from bounding box points (min, max)
    def self.calculate_volume(points)
      return 0 if points.length < 2

      min = points[0]
      max = points[1]
      ((max[0] - min[0]) * (max[1] - min[1]) * (max[2] - min[2])).abs.round(4)
    end

    # Calculate angle between three points (in degrees)
    def self.calculate_angle(points)
      return 0 if points.length < 3

      vertex = points[0]
      p1 = points[1]
      p2 = points[2]

      # Vectors from vertex
      v1 = [p1[0] - vertex[0], p1[1] - vertex[1], p1[2] - vertex[2]]
      v2 = [p2[0] - vertex[0], p2[1] - vertex[1], p2[2] - vertex[2]]

      # Dot product and magnitudes
      dot = v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2]
      mag1 = Math.sqrt(v1[0]**2 + v1[1]**2 + v1[2]**2)
      mag2 = Math.sqrt(v2[0]**2 + v2[1]**2 + v2[2]**2)

      return 0 if mag1.zero? || mag2.zero?

      # Angle in degrees
      angle_rad = Math.acos([[-1, dot / (mag1 * mag2)].max, 1].min)
      (angle_rad * 180 / Math::PI).round(2)
    end

    # Calculate elevation (height) from reference
    def self.calculate_elevation(points, reference_height = 0.0)
      return 0 if points.empty?

      point = points[0]
      (point[1] - reference_height).abs.round(4)
    end

    # Format value with unit
    def formatted_value
      case measurement_type
      when 'distance', 'elevation'
        "#{value.round(2)} #{unit}"
      when 'area'
        "#{value.round(2)} #{unit}"
      when 'volume'
        "#{value.round(2)} #{unit}"
      when 'angle'
        "#{value.round(1)}°"
      else
        "#{value} #{unit}"
      end
    end

    # Get all points as array of 3D coordinates
    def coordinates
      points || []
    end

    # Check if measurement has minimum required points
    def has_valid_points?
      case measurement_type
      when 'distance'
        points.length >= 2
      when 'area'
        points.length >= 3
      when 'volume'
        points.length >= 2
      when 'angle'
        points.length >= 3
      when 'elevation'
        points.length >= 1
      else
        false
      end
    end

    private

    def validate_points_for_measurement_type
      return if points.blank?

      unless points.is_a?(Array)
        errors.add(:points, 'must be an array')
        return
      end

      # Validate each point is a 3D vector
      points.each_with_index do |point, index|
        unless valid_3d_point?(point)
          errors.add(:points, "point at index #{index} must be an array of 3 numeric values [x, y, z]")
        end
      end

      # Validate minimum point count for measurement type
      case measurement_type
      when 'distance'
        errors.add(:points, 'distance requires at least 2 points') if points.length < 2
      when 'area'
        errors.add(:points, 'area requires at least 3 points') if points.length < 3
      when 'volume'
        errors.add(:points, 'volume requires at least 2 points (min and max)') if points.length < 2
      when 'angle'
        errors.add(:points, 'angle requires exactly 3 points (vertex + 2 directions)') if points.length != 3
      when 'elevation'
        errors.add(:points, 'elevation requires at least 1 point') if points.empty?
      end
    end

    def validate_unit_for_measurement_type
      return if measurement_type.blank? || unit.blank?

      valid_units = UNITS[measurement_type]
      return if valid_units.blank?

      unless valid_units.include?(unit)
        errors.add(:unit, "must be one of: #{valid_units.join(', ')} for #{measurement_type} measurements")
      end
    end

    def valid_3d_point?(point)
      point.is_a?(Array) && point.length == 3 && point.all? { |coord| coord.is_a?(Numeric) }
    end
  end
end
