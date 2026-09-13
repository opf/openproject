# frozen_string_literal: true

module Bim
  module Services
    # Visibility Service
    # Manages element visibility filters, isolation mode, and show/hide logic
    # Supports filtering by type, discipline, level, status, and custom properties
    class VisibilityService
      attr_reader :ifc_model, :cache_key

      CACHE_TTL = 5.minutes

      def initialize(ifc_model)
        @ifc_model = ifc_model
        @cache_key = "bim:model:#{ifc_model.id}:visibility"
      end

      # Get current visibility state
      def current_state
        Rails.cache.fetch(@cache_key, expires_in: CACHE_TTL) do
          {
            filters: {},
            overrides: {},
            isolation: {
              active: false,
              element_guids: []
            },
            updated_at: Time.current
          }
        end
      end

      # Apply visibility filters
      def apply_filters(filters:, overrides: {}, user: nil)
        # Validate filters
        validation = validate_filters(filters)
        return validation unless validation[:valid]

        # Get all element GUIDs
        metadata = load_metadata
        all_guids = metadata.map { |e| e['guid'] }

        # Apply filters to determine visible elements
        visible_guids = filter_elements(metadata, filters)

        # Apply individual overrides
        visibility_map = build_visibility_map(all_guids, visible_guids, overrides)

        # Save state
        state = {
          filters: filters,
          overrides: overrides,
          isolation: { active: false, element_guids: [] },
          visibility_map: visibility_map,
          updated_at: Time.current
        }

        save_state(state)

        # Log the change
        log_visibility_change(filters, user) if user

        {
          success: true,
          visible_count: visibility_map.count { |_, v| v[:visible] },
          hidden_count: visibility_map.count { |_, v| !v[:visible] },
          state: state
        }
      end

      # Isolate specific elements (hide all others)
      def isolate_elements(element_guids:, user: nil)
        return { success: false, error: 'No elements specified' } if element_guids.empty?

        metadata = load_metadata
        all_guids = metadata.map { |e| e['guid'] }

        # Validate GUIDs exist
        invalid_guids = element_guids - all_guids
        if invalid_guids.any?
          return { success: false, error: "Invalid GUIDs: #{invalid_guids.join(', ')}" }
        end

        # Build visibility map (only isolated elements visible)
        visibility_map = {}
        all_guids.each do |guid|
          visibility_map[guid] = {
            visible: element_guids.include?(guid),
            opacity: 1.0,
            reason: element_guids.include?(guid) ? 'isolated' : 'hidden_by_isolation'
          }
        end

        # Save state
        state = {
          filters: {},
          overrides: {},
          isolation: {
            active: true,
            element_guids: element_guids,
            activated_at: Time.current
          },
          visibility_map: visibility_map,
          updated_at: Time.current
        }

        save_state(state)

        # Log the change
        log_isolation_change(element_guids, user) if user

        {
          success: true,
          isolated_count: element_guids.size,
          hidden_count: all_guids.size - element_guids.size,
          state: state
        }
      end

      # Reset visibility to default (show all)
      def reset(user: nil)
        metadata = load_metadata
        all_guids = metadata.map { |e| e['guid'] }

        # All elements visible by default
        visibility_map = {}
        all_guids.each do |guid|
          visibility_map[guid] = {
            visible: true,
            opacity: 1.0,
            reason: 'default'
          }
        end

        state = {
          filters: {},
          overrides: {},
          isolation: { active: false, element_guids: [] },
          visibility_map: visibility_map,
          updated_at: Time.current
        }

        save_state(state)

        # Log the change
        log_reset(user) if user

        {
          success: true,
          visible_count: all_guids.size,
          state: state
        }
      end

      # Get visibility state for specific elements
      def element_visibility(element_guids)
        state = current_state
        visibility_map = state[:visibility_map] || {}

        element_guids.map do |guid|
          {
            guid: guid,
            visible: visibility_map.dig(guid, :visible) || true,
            opacity: visibility_map.dig(guid, :opacity) || 1.0,
            reason: visibility_map.dig(guid, :reason) || 'default'
          }
        end
      end

      # Toggle visibility for specific elements
      def toggle_elements(element_guids:, visible:, user: nil)
        state = current_state
        visibility_map = state[:visibility_map] || {}

        # Update visibility for specified elements
        element_guids.each do |guid|
          visibility_map[guid] = {
            visible: visible,
            opacity: visible ? 1.0 : 0.0,
            reason: 'manual_override'
          }
        end

        # Merge with current overrides
        overrides = state[:overrides] || {}
        element_guids.each do |guid|
          overrides[guid] = { visible: visible }
        end

        state[:overrides] = overrides
        state[:visibility_map] = visibility_map
        state[:updated_at] = Time.current

        save_state(state)

        # Log the change
        log_toggle_change(element_guids, visible, user) if user

        {
          success: true,
          toggled_count: element_guids.size,
          visible: visible,
          state: state
        }
      end

      # Get visibility statistics
      def statistics
        state = current_state
        visibility_map = state[:visibility_map] || {}

        total = visibility_map.size
        visible = visibility_map.count { |_, v| v[:visible] }
        hidden = total - visible

        {
          total_elements: total,
          visible_elements: visible,
          hidden_elements: hidden,
          visibility_percentage: total > 0 ? (visible.to_f / total * 100).round(2) : 0,
          filters_active: state[:filters].present?,
          isolation_active: state.dig(:isolation, :active) || false,
          overrides_count: state[:overrides]&.size || 0
        }
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

      # Filter elements based on criteria
      def filter_elements(metadata, filters)
        filtered = metadata

        # Filter by types
        if filters[:types].present?
          filtered = filtered.select { |e| filters[:types].include?(e['type']) }
        end

        # Filter by disciplines
        if filters[:disciplines].present?
          filtered = filtered.select do |e|
            discipline = infer_discipline(e['type'])
            filters[:disciplines].map(&:downcase).include?(discipline.downcase)
          end
        end

        # Filter by levels/storeys
        if filters[:levels].present?
          filtered = filtered.select do |e|
            storey_name = find_storey_name(e['storey'])
            filters[:levels].include?(storey_name)
          end
        end

        # Filter by status (if elements have workflow status)
        if filters[:statuses].present?
          filtered = filtered.select do |e|
            element_link = Bim::ElementLink.find_by(element_id: e['guid'], ifc_model: @ifc_model)
            element_link && filters[:statuses].include?(element_link.status)
          end
        end

        # Filter by custom properties
        if filters[:custom].present?
          property = filters[:custom][:property]
          operator = filters[:custom][:operator]
          value = filters[:custom][:value]

          filtered = filtered.select do |e|
            element_value = e.dig('custom_properties', property) ||
                           e.dig('property_sets', property)

            apply_property_filter(element_value, operator, value)
          end
        end

        filtered.map { |e| e['guid'] }
      end

      # Build visibility map
      def build_visibility_map(all_guids, visible_guids, overrides)
        visibility_map = {}

        all_guids.each do |guid|
          # Check if element has override
          if overrides[guid]
            visibility_map[guid] = {
              visible: overrides[guid][:visible],
              opacity: overrides[guid][:opacity] || 1.0,
              color: overrides[guid][:color],
              reason: 'override'
            }
          else
            # Use filter result
            visibility_map[guid] = {
              visible: visible_guids.include?(guid),
              opacity: 1.0,
              reason: visible_guids.include?(guid) ? 'filter_match' : 'filter_exclude'
            }
          end
        end

        visibility_map
      end

      # Apply property filter
      def apply_property_filter(element_value, operator, filter_value)
        case operator
        when 'equals', '=='
          element_value.to_s == filter_value.to_s
        when 'not_equals', '!='
          element_value.to_s != filter_value.to_s
        when 'contains'
          element_value.to_s.downcase.include?(filter_value.to_s.downcase)
        when 'greater_than', '>'
          element_value.to_f > filter_value.to_f
        when 'less_than', '<'
          element_value.to_f < filter_value.to_f
        when 'greater_than_or_equal', '>='
          element_value.to_f >= filter_value.to_f
        when 'less_than_or_equal', '<='
          element_value.to_f <= filter_value.to_f
        else
          false
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

      # Find storey name by GUID
      def find_storey_name(storey_guid)
        return nil unless storey_guid

        metadata = load_metadata
        storey = metadata.find { |e| e['guid'] == storey_guid }

        storey ? storey['name'] : storey_guid
      end

      # Validate filters
      def validate_filters(filters)
        errors = []

        # Validate types
        if filters[:types] && !filters[:types].is_a?(Array)
          errors << 'Types must be an array'
        end

        # Validate disciplines
        if filters[:disciplines]
          valid_disciplines = %w[Architecture Structure MEP Civil Other]
          invalid = filters[:disciplines] - valid_disciplines.map(&:downcase)
          errors << "Invalid disciplines: #{invalid.join(', ')}" if invalid.any?
        end

        # Validate custom filter
        if filters[:custom]
          unless filters[:custom][:property] && filters[:custom][:operator] && filters[:custom].key?(:value)
            errors << 'Custom filter requires property, operator, and value'
          end

          valid_operators = %w[equals not_equals contains greater_than less_than greater_than_or_equal less_than_or_equal == != > < >= <=]
          unless valid_operators.include?(filters[:custom][:operator])
            errors << "Invalid operator: #{filters[:custom][:operator]}"
          end
        end

        if errors.any?
          { valid: false, errors: errors }
        else
          { valid: true }
        end
      end

      # Save visibility state
      def save_state(state)
        Rails.cache.write(@cache_key, state, expires_in: CACHE_TTL)
      end

      # Logging methods

      def log_visibility_change(filters, user)
        Bim::AuditLog.log(
          user: user,
          project: @ifc_model.project,
          action: :visibility_filter_applied,
          entity_type: 'IfcModel',
          entity_id: @ifc_model.id,
          details: {
            model_id: @ifc_model.id,
            filters: filters
          },
          severity: :info,
          tags: ['visibility', 'filter']
        )
      end

      def log_isolation_change(element_guids, user)
        Bim::AuditLog.log(
          user: user,
          project: @ifc_model.project,
          action: :isolation_mode_activated,
          entity_type: 'IfcModel',
          entity_id: @ifc_model.id,
          details: {
            model_id: @ifc_model.id,
            isolated_elements: element_guids.size,
            element_guids: element_guids
          },
          severity: :info,
          tags: ['visibility', 'isolation']
        )
      end

      def log_reset(user)
        Bim::AuditLog.log(
          user: user,
          project: @ifc_model.project,
          action: :visibility_reset,
          entity_type: 'IfcModel',
          entity_id: @ifc_model.id,
          details: {
            model_id: @ifc_model.id
          },
          severity: :info,
          tags: ['visibility', 'reset']
        )
      end

      def log_toggle_change(element_guids, visible, user)
        Bim::AuditLog.log(
          user: user,
          project: @ifc_model.project,
          action: :elements_visibility_toggled,
          entity_type: 'IfcModel',
          entity_id: @ifc_model.id,
          details: {
            model_id: @ifc_model.id,
            element_count: element_guids.size,
            visible: visible
          },
          severity: :info,
          tags: ['visibility', 'toggle']
        )
      end
    end
  end
end
