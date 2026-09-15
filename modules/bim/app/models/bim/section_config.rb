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
  class SectionConfig < ApplicationRecord
    self.table_name = 'bim_section_configs'

    belongs_to :ifc_model, class_name: 'Bim::IfcModels::IfcModel'
    belongs_to :user, optional: true

    validates :name, presence: true, length: { maximum: 255 }
    validates :name, uniqueness: { scope: :ifc_model_id }
    validates :edge_color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: 'must be a valid hex color' }, allow_nil: true
    validates :fill_color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: 'must be a valid hex color' }, allow_nil: true
    validates :fill_opacity,
              numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 },
              allow_nil: true

    validate :validate_section_boxes
    validate :validate_section_planes

    scope :public_configs, -> { where(is_public: true) }
    scope :private_configs, -> { where(is_public: false) }
    scope :for_model, ->(model_id) { where(ifc_model_id: model_id) }
    scope :for_user, ->(user_id) { where(user_id: user_id) }

    # Helper methods for section boxes
    def add_section_box(min:, max:, enabled: true)
      boxes = section_boxes || []
      boxes << { 'min' => min, 'max' => max, 'enabled' => enabled }
      self.section_boxes = boxes
    end

    def remove_section_box(index)
      boxes = section_boxes || []
      boxes.delete_at(index)
      self.section_boxes = boxes
    end

    def enabled_section_boxes
      (section_boxes || []).select { |box| box['enabled'] }
    end

    # Helper methods for section planes
    def add_section_plane(pos:, dir:, enabled: true)
      planes = section_planes || []
      planes << { 'pos' => pos, 'dir' => dir, 'enabled' => enabled }
      self.section_planes = planes
    end

    def remove_section_plane(index)
      planes = section_planes || []
      planes.delete_at(index)
      self.section_planes = planes
    end

    def enabled_section_planes
      (section_planes || []).select { |plane| plane['enabled'] }
    end

    # Configuration summary
    def configuration_summary
      {
        boxes_count: (section_boxes || []).length,
        planes_count: (section_planes || []).length,
        enabled_boxes: enabled_section_boxes.length,
        enabled_planes: enabled_section_planes.length,
        show_edges: show_edges,
        show_fills: show_fills
      }
    end

    private

    def validate_section_boxes
      return if section_boxes.blank?

      unless section_boxes.is_a?(Array)
        errors.add(:section_boxes, 'must be an array')
        return
      end

      section_boxes.each_with_index do |box, index|
        unless box.is_a?(Hash)
          errors.add(:section_boxes, "box at index #{index} must be a hash")
          next
        end

        validate_box_bounds(box, index)
      end
    end

    def validate_box_bounds(box, index)
      min = box['min']
      max = box['max']

      unless valid_vector?(min)
        errors.add(:section_boxes, "box at index #{index}: 'min' must be an array of 3 numeric values")
      end

      unless valid_vector?(max)
        errors.add(:section_boxes, "box at index #{index}: 'max' must be an array of 3 numeric values")
      end

      return unless valid_vector?(min) && valid_vector?(max)

      # Validate that max > min for each axis
      (0..2).each do |i|
        if max[i] <= min[i]
          errors.add(:section_boxes, "box at index #{index}: max[#{i}] must be greater than min[#{i}]")
        end
      end
    end

    def validate_section_planes
      return if section_planes.blank?

      unless section_planes.is_a?(Array)
        errors.add(:section_planes, 'must be an array')
        return
      end

      section_planes.each_with_index do |plane, index|
        unless plane.is_a?(Hash)
          errors.add(:section_planes, "plane at index #{index} must be a hash")
          next
        end

        validate_plane_vectors(plane, index)
      end
    end

    def validate_plane_vectors(plane, index)
      pos = plane['pos']
      dir = plane['dir']

      unless valid_vector?(pos)
        errors.add(:section_planes, "plane at index #{index}: 'pos' must be an array of 3 numeric values")
      end

      unless valid_vector?(dir)
        errors.add(:section_planes, "plane at index #{index}: 'dir' must be an array of 3 numeric values")
      end

      return unless valid_vector?(dir)

      # Validate that direction vector is normalized or at least non-zero
      magnitude = Math.sqrt(dir[0]**2 + dir[1]**2 + dir[2]**2)
      if magnitude.zero?
        errors.add(:section_planes, "plane at index #{index}: 'dir' must be a non-zero vector")
      end
    end

    def valid_vector?(vector)
      vector.is_a?(Array) && vector.length == 3 && vector.all? { |v| v.is_a?(Numeric) }
    end
  end
end
