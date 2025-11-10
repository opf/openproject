# frozen_string_literal: true

module Bim
  module Services
    # Color Scheme Service
    # Manages element color overrides for visual coding
    # Supports color by status, discipline, type, property, and custom schemes
    class ColorSchemeService
      attr_reader :ifc_model, :cache_key

      CACHE_TTL = 10.minutes

      # Pre-defined color schemes
      SCHEMES = {
        'by_status' => {
          'approved' => '#00FF00',
          'in_review' => '#FFFF00',
          'rejected' => '#FF0000',
          'draft' => '#CCCCCC',
          'pending' => '#FFA500'
        },
        'by_discipline' => {
          'Architecture' => '#4A90E2',
          'Structure' => '#7F7F7F',
          'MEP' => '#50E3C2',
          'Civil' => '#BD10E0',
          'Other' => '#9B9B9B'
        },
        'by_type' => {
          'IfcWall' => '#D0D0D0',
          'IfcBeam' => '#8B4513',
          'IfcColumn' => '#A0522D',
          'IfcSlab' => '#C0C0C0',
          'IfcDoor' => '#4169E1',
          'IfcWindow' => '#87CEEB',
          'IfcRoof' => '#8B0000',
          'IfcStair' => '#CD853F',
          'IfcRailing' => '#708090',
          'IfcFlowSegment' => '#00CED1',
          'IfcFlowFitting' => '#48D1CC',
          'IfcFlowTerminal' => '#20B2AA'
        },
        'by_clash_status' => {
          'has_clash' => '#FF0000',
          'clash_resolved' => '#00FF00',
          'no_clash' => '#FFFFFF'
        }
      }.freeze

      def initialize(ifc_model)
        @ifc_model = ifc_model
        @cache_key = "bim:model:#{ifc_model.id}:colors"
      end

      # Get available color schemes
      def available_schemes
        {
          schemes: SCHEMES,
          custom_schemes: load_custom_schemes
        }
      end

      # Apply a color scheme
      def apply_scheme(scheme_name:, custom_colors: {}, user: nil)
        # Validate scheme
        unless SCHEMES.key?(scheme_name) || scheme_name == 'custom'
          return { success: false, error: "Unknown scheme: #{scheme_name}" }
        end

        metadata = load_metadata

        # Get base scheme colors
        base_colors = SCHEMES[scheme_name] || {}

        # Override with custom colors
        colors = base_colors.merge(custom_colors)

        # Build color map for all elements
        color_map = build_color_map(metadata, scheme_name, colors)

        # Save state
        state = {
          scheme: scheme_name,
          colors: colors,
          color_map: color_map,
          applied_at: Time.current
        }

        save_state(state)

        # Log the change
        log_scheme_change(scheme_name, user) if user

        {
          success: true,
          scheme: scheme_name,
          elements_colored: color_map.size,
          state: state
        }
      end

      # Apply color by property value
      def apply_by_property(property_name:, color_mapping:, default_color: nil, user: nil)
        metadata = load_metadata

        color_map = {}

        metadata.each do |element|
          # Get property value
          property_value = element.dig('custom_properties', property_name) ||
                          element.dig('property_sets', property_name) ||
                          element[property_name]

          # Map to color
          if property_value && color_mapping.key?(property_value.to_s)
            color = color_mapping[property_value.to_s]
          elsif default_color
            color = default_color
          else
            next # Skip elements without matching property
          end

          color_map[element['guid']] = {
            color: color,
            property: property_name,
            value: property_value
          }
        end

        # Save state
        state = {
          scheme: 'by_property',
          property: property_name,
          color_mapping: color_mapping,
          default_color: default_color,
          color_map: color_map,
          applied_at: Time.current
        }

        save_state(state)

        # Log the change
        log_property_coloring(property_name, user) if user

        {
          success: true,
          property: property_name,
          elements_colored: color_map.size,
          state: state
        }
      end

      # Reset colors to original
      def reset(user: nil)
        state = {
          scheme: nil,
          colors: {},
          color_map: {},
          applied_at: Time.current
        }

        save_state(state)

        # Log the change
        log_reset(user) if user

        {
          success: true,
          message: 'Colors reset to original'
        }
      end

      # Get current color state
      def current_state
        Rails.cache.fetch(@cache_key, expires_in: CACHE_TTL) do
          {
            scheme: nil,
            colors: {},
            color_map: {},
            applied_at: nil
          }
        end
      end

      # Get color for specific element
      def element_color(element_guid)
        state = current_state
        state[:color_map]&.dig(element_guid, :color)
      end

      # Get colors for multiple elements
      def element_colors(element_guids)
        state = current_state
        color_map = state[:color_map] || {}

        element_guids.map do |guid|
          {
            guid: guid,
            color: color_map.dig(guid, :color),
            property: color_map.dig(guid, :property),
            value: color_map.dig(guid, :value)
          }
        end
      end

      # Clear cached state
      def clear_cache
        Rails.cache.delete(@cache_key)
      end

      private

      # Load metadata
      def load_metadata
        metadata_cache_key = "bim:model:#{@ifc_model.id}:metadata"

        Rails.cache.fetch(metadata_cache_key, expires_in: 1.hour) do
          if @ifc_model.ifc_model_metadata
            @ifc_model.ifc_model_metadata.metadata_json || []
          else
            []
          end
        end
      end

      # Build color map based on scheme
      def build_color_map(metadata, scheme_name, colors)
        color_map = {}

        metadata.each do |element|
          color = case scheme_name
                  when 'by_status'
                    get_status_color(element, colors)
                  when 'by_discipline'
                    get_discipline_color(element, colors)
                  when 'by_type'
                    get_type_color(element, colors)
                  when 'by_clash_status'
                    get_clash_color(element, colors)
                  when 'custom'
                    colors[element['guid']]
                  end

          color_map[element['guid']] = { color: color } if color
        end

        color_map
      end

      # Get status color for element
      def get_status_color(element, colors)
        # Check element link for status
        element_link = Bim::ElementLink.find_by(
          element_id: element['guid'],
          ifc_model: @ifc_model
        )

        return nil unless element_link

        colors[element_link.status] || colors['draft']
      end

      # Get discipline color
      def get_discipline_color(element, colors)
        discipline = infer_discipline(element['type'])
        colors[discipline] || colors['Other']
      end

      # Get type color
      def get_type_color(element, colors)
        colors[element['type']]
      end

      # Get clash color
      def get_clash_color(element, colors)
        # Check if element has clashes
        has_clash = Bim::Clash.where(ifc_model: @ifc_model)
                              .where('element_a_id = ? OR element_b_id = ?',
                                     element['guid'], element['guid'])
                              .where.not(status: :resolved)
                              .exists?

        if has_clash
          clash_resolved = Bim::Clash.where(ifc_model: @ifc_model)
                                     .where('element_a_id = ? OR element_b_id = ?',
                                            element['guid'], element['guid'])
                                     .where(status: :resolved)
                                     .exists?

          clash_resolved ? colors['clash_resolved'] : colors['has_clash']
        else
          colors['no_clash']
        end
      end

      # Infer discipline from IFC type
      def infer_discipline(ifc_type)
        case ifc_type
        when /^IfcWall|IfcDoor|IfcWindow|IfcSlab|IfcRoof|IfcStair|IfcRailing|IfcCurtainWall/
          'Architecture'
        when /^IfcBeam|IfcColumn|IfcFooting|IfcPile|IfcReinforcingBar|IfcTendon/
          'Structure'
        when /^IfcFlow|IfcDistribution/
          'MEP'
        when /^IfcBridge|IfcRoad|IfcRailway/
          'Civil'
        else
          'Other'
        end
      end

      # Load custom color schemes
      def load_custom_schemes
        # Could be loaded from database, user preferences, or project settings
        # For now, return empty hash
        {}
      end

      # Save color state
      def save_state(state)
        Rails.cache.write(@cache_key, state, expires_in: CACHE_TTL)
      end

      # Logging methods

      def log_scheme_change(scheme_name, user)
        Bim::AuditLog.log(
          user: user,
          project: @ifc_model.project,
          action: :color_scheme_applied,
          entity_type: 'IfcModel',
          entity_id: @ifc_model.id,
          details: {
            model_id: @ifc_model.id,
            scheme: scheme_name
          },
          severity: :info,
          tags: ['colors', 'scheme']
        )
      end

      def log_property_coloring(property_name, user)
        Bim::AuditLog.log(
          user: user,
          project: @ifc_model.project,
          action: :property_coloring_applied,
          entity_type: 'IfcModel',
          entity_id: @ifc_model.id,
          details: {
            model_id: @ifc_model.id,
            property: property_name
          },
          severity: :info,
          tags: ['colors', 'property']
        )
      end

      def log_reset(user)
        Bim::AuditLog.log(
          user: user,
          project: @ifc_model.project,
          action: :colors_reset,
          entity_type: 'IfcModel',
          entity_id: @ifc_model.id,
          details: {
            model_id: @ifc_model.id
          },
          severity: :info,
          tags: ['colors', 'reset']
        )
      end
    end
  end
end
