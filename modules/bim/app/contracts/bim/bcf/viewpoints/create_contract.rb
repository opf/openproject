#-- copyright
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
#++

module Bim::Bcf
  module Viewpoints
    class CreateContract < ::ModelContract
      include ::Bim::Bcf::Concerns::ManageBcfGuarded

      WHITELISTED_PROPERTIES = %w(guid
                                  index
                                  snapshot
                                  orthogonal_camera
                                  perspective_camera
                                  clipping_planes
                                  bitmaps
                                  lines
                                  components).freeze

      ORTHOGONAL_CAMERA_PROPERTIES = %w(camera_view_point
                                        camera_direction
                                        camera_up_vector
                                        view_to_world_scale).freeze

      PERSPECTIVE_CAMERA_PROPERTIES = %w(camera_view_point
                                         camera_direction
                                         camera_up_vector
                                         field_of_view).freeze

      LINES_PROPERTIES = %w(start_point
                            end_point).freeze

      CLIPPING_PLANES_PROPERTIES = %w(location
                                      direction).freeze

      COMPONENTS_PROPERTIES = %w(visibility
                                 selection
                                 coloring).freeze

      COMPONENT_PROPERTIES = %w(ifc_guid
                                originating_system
                                authoring_tool_id).freeze

      COLORING_PROPERTIES = %w(color
                               components).freeze

      VISIBILITY_PROPERTIES = %w(default_visibility
                                 exceptions
                                 view_setup_hints).freeze

      VIEW_SETUP_HINTS_PROPERTIES = %w(spaces_visible
                                       space_boundaries_visible
                                       openings_visible).freeze

      COLOR_REGEXP = /([0-9a-f]{2})?[0-9a-f]{6}/

      WHITELISTED_DIMENSIONS = %w(x y z).freeze

      attribute :uuid
      attribute :issue
      attribute :snapshot
      attribute :json_viewpoint do
        validate_json_viewpoint_blank
        validate_json_viewpoint_hash

        next if errors.any?

        validate_properties
        validate_snapshot
        validate_index
        validate_orthogonal_camera
        validate_perspective_camera
        validate_lines
        validate_clipping_planes
        validate_bitmaps
        validate_components
        validate_guid
      end

      def validate_json_viewpoint_blank
        errors.add(:json_viewpoint, :blank) if viewpoint.blank?
      end

      def validate_json_viewpoint_hash
        errors.add(:json_viewpoint, :no_json) if viewpoint.present? && !viewpoint.is_a?(Hash)
      end

      def validate_properties
        errors.add(:json_viewpoint, :unsupported_key) if viewpoint.present? && (viewpoint.keys - WHITELISTED_PROPERTIES).any?
      end

      def validate_snapshot
        return unless (sjson = viewpoint["snapshot"])

        errors.add(:json_viewpoint, :snapshot_type_unsupported) unless %w(jpg png).include? sjson["snapshot_type"]
        errors.add(:json_viewpoint, :snapshot_data_blank) if sjson["snapshot_data"].blank?
      end

      def validate_index
        return unless (ijson = viewpoint["index"])

        errors.add(:json_viewpoint, :index_not_integer) unless ijson.is_a? Integer
      end

      def validate_orthogonal_camera
        return unless (ocjson = viewpoint["orthogonal_camera"])

        if ocjson.keys != ORTHOGONAL_CAMERA_PROPERTIES ||
           ocjson.except("view_to_world_scale").any? { |_, direction| invalid_direction?(direction) } ||
           !ocjson["view_to_world_scale"].is_a?(Numeric)
          errors.add(:json_viewpoint, :invalid_orthogonal_camera)
        end
      end

      def validate_perspective_camera
        return unless (pcjson = viewpoint["perspective_camera"])

        if pcjson.keys != PERSPECTIVE_CAMERA_PROPERTIES ||
           pcjson.except("field_of_view").any? { |_, direction| invalid_direction?(direction) } ||
           !pcjson["field_of_view"].is_a?(Numeric)
          errors.add(:json_viewpoint, :invalid_perspective_camera)
        end
      end

      def validate_lines
        return unless (ljson = viewpoint["lines"])

        if !ljson.is_a?(Array) ||
           ljson.any? { |line| invalid_line?(line) }
          errors.add(:json_viewpoint, :invalid_lines)
        end
      end

      def validate_clipping_planes
        return unless (cpjson = viewpoint["clipping_planes"])

        if !cpjson.is_a?(Array) ||
           cpjson.any? { |cp| invalid_clipping_plane?(cp) }
          errors.add(:json_viewpoint, :invalid_clipping_planes)
        end
      end

      def validate_bitmaps
        errors.add(:json_viewpoint, :bitmaps_not_writable) if viewpoint["bitmaps"]
      end

      def validate_components
        return unless (cjson = viewpoint["components"])

        if !cjson.is_a?(Hash) ||
           invalid_components_properties?(cjson)
          errors.add(:json_viewpoint, :invalid_components)
        end
      end

      def validate_guid
        return unless (json_guid = viewpoint["guid"])

        errors.add(:json_viewpoint, :mismatching_guid) if json_guid != model.uuid
      end

      def invalid_components_properties?(json)
        (json.keys - COMPONENTS_PROPERTIES).any? ||
          invalid_visibility?(json["visibility"]) ||
          invalid_components?(json["selection"]) ||
          invalid_colorings?(json["coloring"])
      end

      def invalid_line?(line)
        invalid_hash_point?(line, LINES_PROPERTIES)
      end

      def invalid_clipping_plane?(line)
        invalid_hash_point?(line, CLIPPING_PLANES_PROPERTIES)
      end

      def invalid_hash_point?(hash, whitelist)
        !hash.is_a?(Hash) ||
          hash.keys != whitelist ||
          hash.values.any? { |v| invalid_point?(v) }
      end

      def invalid_visibility?(visibility)
        visibility.nil? ||
          !visibility.is_a?(Hash) ||
          (visibility.keys - VISIBILITY_PROPERTIES).any? ||
          invalid_default_visibility?(visibility["default_visibility"]) ||
          invalid_components?(visibility["exceptions"]) ||
          invalid_view_setup_hints?(visibility["view_setup_hints"])
      end

      def invalid_components?(components)
        return false if components.blank?

        !components.is_a?(Array) || components.any? { |component| invalid_component?(component) }
      end

      def invalid_colorings?(colorings)
        return false if colorings.blank?

        !colorings.is_a?(Array) || colorings.any? { |coloring| invalid_coloring?(coloring) }
      end

      def invalid_component?(component)
        !component.is_a?(Hash) ||
          component.empty? ||
          (component.keys - COMPONENT_PROPERTIES).any? ||
          component.values.any? { |v| !v.is_a?(String) }
      end

      def invalid_coloring?(coloring)
        !coloring.is_a?(Hash) ||
          coloring.keys != COLORING_PROPERTIES ||
          invalid_color?(coloring["color"]) ||
          invalid_components?(coloring["components"])
      end

      def invalid_color?(color)
        !(color.is_a?(String) && color.match?(COLOR_REGEXP))
      end

      def invalid_direction?(direction)
        !direction.is_a?(Hash) ||
          direction.keys != WHITELISTED_DIMENSIONS ||
          direction.values.any? { |v| !v.is_a? Numeric }
      end
      alias_method :invalid_point?, :invalid_direction?

      def invalid_default_visibility?(visibility)
        visibility.present? &&
          no_boolean?(visibility)
      end

      def invalid_view_setup_hints?(hints)
        return false if hints.nil?

        !hints.is_a?(Hash) ||
          (hints.keys - VIEW_SETUP_HINTS_PROPERTIES).any? ||
          hints.values.any? { |v| no_boolean?(v) }
      end

      def no_boolean?(property)
        !(property.is_a?(TrueClass) || property.is_a?(FalseClass))
      end

      def viewpoint
        model.json_viewpoint
      end
    end
  end
end
