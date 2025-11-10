# frozen_string_literal: true

module Bim
  module Services
    # Element Properties Service
    # Extracts and formats element properties from IFC metadata
    # Groups properties by category for easy display
    class ElementPropertiesService
      attr_reader :ifc_model, :element_guid

      CACHE_TTL = 15.minutes

      def initialize(ifc_model, element_guid)
        @ifc_model = ifc_model
        @element_guid = element_guid
        @cache_key = "bim:model:#{ifc_model.id}:element:#{element_guid}:properties"
      end

      # Get all properties grouped by category
      def properties
        Rails.cache.fetch(@cache_key, expires_in: CACHE_TTL) do
          element_data = find_element_data

          return {} unless element_data

          {
            basic: extract_basic_properties(element_data),
            geometry: extract_geometry_properties(element_data),
            materials: extract_material_properties(element_data),
            status: extract_status_properties(element_data),
            custom: extract_custom_properties(element_data)
          }
        end
      end

      # Get property history from audit logs
      def property_history
        Bim::AuditLog
          .for_entity('BimElement', @element_guid)
          .where("details->>'action' IN (?)", ['property_updated', 'element_updated'])
          .order(created_at: :desc)
          .limit(50)
          .map do |log|
            {
              timestamp: log.created_at,
              user: log.user&.name || 'System',
              action: log.action_type,
              changes: log.changes || {},
              details: log.details || {}
            }
          end
      end

      # Get related elements (e.g., doors in wall, windows in wall)
      def related_elements
        element_data = find_element_data
        return [] unless element_data

        metadata = load_all_metadata

        # Find elements where parent_guid matches this element
        children = metadata.select { |e| e['parent_guid'] == @element_guid }

        # Find parent element
        parent = metadata.find { |e| e['guid'] == element_data['parent_guid'] } if element_data['parent_guid']

        related = []

        related << {
          relationship: 'parent',
          guid: parent['guid'],
          name: parent['name'],
          type: parent['type']
        } if parent

        children.each do |child|
          related << {
            relationship: 'child',
            guid: child['guid'],
            name: child['name'],
            type: child['type']
          }
        end

        related
      end

      # Update custom properties (user-defined only)
      def update_properties(properties, user:)
        element_data = find_element_data
        return { success: false, error: 'Element not found' } unless element_data

        # Only allow updating custom properties
        custom_props = properties.slice(:custom)

        # Validate properties
        validation = validate_properties(custom_props)
        return validation unless validation[:valid]

        # Store updated properties
        element_data['custom_properties'] ||= {}
        element_data['custom_properties'].merge!(custom_props[:custom] || {})

        # Save to metadata
        save_element_data(element_data)

        # Log the change
        Bim::AuditLog.log(
          user: user,
          project: @ifc_model.project,
          action: :element_property_updated,
          entity_type: 'BimElement',
          entity_id: @element_guid,
          changes: { custom_properties: custom_props[:custom] },
          details: {
            element_guid: @element_guid,
            element_type: element_data['type'],
            properties_updated: custom_props[:custom]&.keys || []
          },
          severity: :low
        )

        # Clear cache
        clear_cache

        { success: true, properties: properties }
      end

      # Clear cached properties
      def clear_cache
        Rails.cache.delete(@cache_key)
      end

      private

      # Find element data from metadata
      def find_element_data
        metadata = load_all_metadata
        metadata.find { |e| e['guid'] == @element_guid }
      end

      # Load all metadata
      def load_all_metadata
        metadata_cache_key = "bim:model:#{@ifc_model.id}:metadata"

        Rails.cache.fetch(metadata_cache_key, expires_in: 1.hour) do
          if @ifc_model.ifc_model_metadata
            @ifc_model.ifc_model_metadata.metadata_json || []
          else
            []
          end
        end
      end

      # Extract basic properties
      def extract_basic_properties(element_data)
        {
          'Name' => element_data['name'] || 'Unnamed',
          'Type' => element_data['type'] || 'Unknown',
          'GUID' => element_data['guid'],
          'Level/Storey' => find_storey_name(element_data['storey']),
          'Discipline' => infer_discipline(element_data['type']),
          'Description' => element_data['description']
        }.compact
      end

      # Extract geometry properties
      def extract_geometry_properties(element_data)
        geometry = element_data['geometry'] || {}

        properties = {}

        # Volume
        if geometry['volume']
          properties['Volume'] = format_volume(geometry['volume'])
        end

        # Area
        if geometry['area']
          properties['Area'] = format_area(geometry['area'])
        end

        # Dimensions
        if geometry['height']
          properties['Height'] = format_length(geometry['height'])
        end

        if geometry['width']
          properties['Width'] = format_length(geometry['width'])
        end

        if geometry['length']
          properties['Length'] = format_length(geometry['length'])
        end

        if geometry['depth']
          properties['Depth'] = format_length(geometry['depth'])
        end

        # Perimeter
        if geometry['perimeter']
          properties['Perimeter'] = format_length(geometry['perimeter'])
        end

        properties
      end

      # Extract material properties
      def extract_material_properties(element_data)
        materials = element_data['materials'] || element_data['material'] || {}

        if materials.is_a?(String)
          return { 'Material' => materials }
        end

        properties = {}

        # Material name
        if materials['name']
          properties['Material'] = materials['name']
        end

        # Finish
        if materials['finish']
          properties['Finish'] = materials['finish']
        end

        # Fire rating
        if materials['fire_rating']
          properties['Fire Rating'] = materials['fire_rating']
        end

        # Acoustic rating
        if materials['acoustic_rating']
          properties['Acoustic Rating'] = materials['acoustic_rating']
        end

        # Thermal properties
        if materials['thermal_conductivity']
          properties['Thermal Conductivity'] = materials['thermal_conductivity']
        end

        # Load bearing
        if materials['load_bearing']
          properties['Load Bearing'] = materials['load_bearing'] ? 'Yes' : 'No'
        end

        properties
      end

      # Extract status properties (from workflows, element links, etc.)
      def extract_status_properties(element_data)
        properties = {}

        # Check for element link
        element_link = Bim::ElementLink.find_by(element_id: @element_guid, ifc_model: @ifc_model)

        if element_link
          properties['Status'] = element_link.status.humanize
          properties['Assigned To'] = element_link.assigned_to&.name if element_link.assigned_to
          properties['Work Package'] = element_link.work_package&.subject if element_link.work_package
          properties['Last Modified'] = element_link.updated_at.strftime('%Y-%m-%d %H:%M')
          properties['Modified By'] = element_link.updated_by&.name if element_link.updated_by
        end

        # Check for workflow state (if element is in a workflow)
        if element_data['workflow_state']
          properties['Workflow State'] = element_data['workflow_state'].humanize
        end

        # Approval status
        if element_data['approval_status']
          properties['Approval Status'] = element_data['approval_status'].humanize
        end

        properties
      end

      # Extract custom properties (user-defined or IFC property sets)
      def extract_custom_properties(element_data)
        custom = element_data['custom_properties'] || {}
        psets = element_data['property_sets'] || {}

        # Merge IFC property sets with custom properties
        all_custom = {}

        # Add IFC property sets (Pset_*)
        psets.each do |pset_name, pset_values|
          next unless pset_values.is_a?(Hash)

          pset_values.each do |key, value|
            all_custom["#{pset_name}.#{key}"] = format_property_value(value)
          end
        end

        # Add custom properties (override Psets if same key)
        custom.each do |key, value|
          all_custom[key] = format_property_value(value)
        end

        all_custom
      end

      # Find storey name by GUID
      def find_storey_name(storey_guid)
        return nil unless storey_guid

        metadata = load_all_metadata
        storey = metadata.find { |e| e['guid'] == storey_guid }

        storey ? storey['name'] : storey_guid
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

      # Format property value
      def format_property_value(value)
        case value
        when TrueClass, FalseClass
          value ? 'Yes' : 'No'
        when Numeric
          value.to_s
        when String
          value
        when Hash
          value.to_json
        when Array
          value.join(', ')
        else
          value.to_s
        end
      end

      # Format volume with units
      def format_volume(volume)
        "#{volume.round(2)} m³"
      end

      # Format area with units
      def format_area(area)
        "#{area.round(2)} m²"
      end

      # Format length with units
      def format_length(length)
        "#{length.round(2)} m"
      end

      # Validate properties before update
      def validate_properties(properties)
        errors = []

        # Validate custom properties
        if properties[:custom]
          properties[:custom].each do |key, value|
            if key.blank?
              errors << 'Property name cannot be blank'
            end

            if value.to_s.length > 1000
              errors << "Property '#{key}' value too long (max 1000 characters)"
            end
          end
        end

        if errors.any?
          { valid: false, errors: errors }
        else
          { valid: true }
        end
      end

      # Save element data back to metadata
      def save_element_data(element_data)
        metadata = load_all_metadata

        # Find and update element
        index = metadata.find_index { |e| e['guid'] == @element_guid }

        if index
          metadata[index] = element_data

          # Save to database
          if @ifc_model.ifc_model_metadata
            @ifc_model.ifc_model_metadata.update!(metadata_json: metadata)
          else
            @ifc_model.create_ifc_model_metadata!(metadata_json: metadata)
          end

          # Clear cache
          Rails.cache.delete("bim:model:#{@ifc_model.id}:metadata")
        end
      end
    end
  end
end
