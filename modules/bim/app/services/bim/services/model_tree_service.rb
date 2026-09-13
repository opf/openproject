# frozen_string_literal: true

module Bim
  module Services
    # Model Tree Service
    # Builds hierarchical tree structure from IFC model metadata
    # Supports spatial, type-based, and discipline-based views
    class ModelTreeService
      attr_reader :ifc_model, :view_mode, :cache_key

      VIEW_MODES = %w[spatial type discipline custom].freeze
      CACHE_TTL = 1.hour

      def initialize(ifc_model, view_mode: 'spatial')
        @ifc_model = ifc_model
        @view_mode = view_mode.to_s
        @cache_key = "bim:model:#{ifc_model.id}:tree:#{view_mode}"

        raise ArgumentError, "Invalid view mode: #{view_mode}" unless VIEW_MODES.include?(@view_mode)
      end

      # Get root nodes of tree
      def root_nodes
        Rails.cache.fetch(@cache_key, expires_in: CACHE_TTL) do
          case @view_mode
          when 'spatial'
            build_spatial_tree
          when 'type'
            build_type_tree
          when 'discipline'
            build_discipline_tree
          when 'custom'
            build_custom_tree
          end
        end
      end

      # Get children of a specific node
      def children_of(node_id)
        cache_key_children = "#{@cache_key}:children:#{node_id}"

        Rails.cache.fetch(cache_key_children, expires_in: CACHE_TTL) do
          node = find_node(node_id)
          return [] unless node

          fetch_children(node)
        end
      end

      # Search tree nodes
      def search(query, filters = {})
        results = []

        # Get all metadata entries
        metadata = @ifc_model.ifc_model_metadata || extract_metadata_from_xkt

        # Search by name
        if query.present?
          results += search_by_name(metadata, query)
        end

        # Apply filters
        if filters[:types].present?
          results = results.select { |r| filters[:types].include?(r[:type]) }
        end

        if filters[:levels].present?
          results = results.select { |r| filters[:levels].include?(r[:level]) }
        end

        if filters[:disciplines].present?
          results = results.select { |r| filters[:disciplines].include?(r[:discipline]) }
        end

        results.uniq
      end

      # Clear cached tree
      def clear_cache
        Rails.cache.delete(@cache_key)
        Rails.cache.delete_matched("#{@cache_key}:*")
      end

      private

      # Build spatial hierarchy (IFC building structure)
      def build_spatial_tree
        metadata = load_metadata

        # Start with IfcProject as root
        project_elements = metadata.select { |e| e['type'] == 'IfcProject' }

        project_elements.map do |project|
          build_node(
            id: "project_#{project['guid']}",
            name: project['name'] || 'Unnamed Project',
            type: 'IfcProject',
            guid: project['guid'],
            level: 0,
            children_count: count_children(project, metadata, 'spatial'),
            has_children: true,
            icon: 'project'
          )
        end
      end

      # Build type-based hierarchy
      def build_type_tree
        metadata = load_metadata

        # Group by IFC type
        types = metadata.map { |e| e['type'] }.compact.uniq.sort

        types.map.with_index do |type, index|
          elements_of_type = metadata.select { |e| e['type'] == type }

          build_node(
            id: "type_#{type}",
            name: type,
            type: 'TypeGroup',
            level: 0,
            children_count: elements_of_type.size,
            has_children: elements_of_type.size > 0,
            icon: icon_for_type(type)
          )
        end
      end

      # Build discipline-based hierarchy
      def build_discipline_tree
        metadata = load_metadata

        # Define discipline mappings
        disciplines = {
          'Architecture' => %w[IfcWall IfcDoor IfcWindow IfcSlab IfcRoof IfcStair IfcRailing IfcCurtainWall],
          'Structure' => %w[IfcBeam IfcColumn IfcFooting IfcPile IfcReinforcingBar IfcTendon],
          'MEP' => %w[IfcFlowSegment IfcFlowFitting IfcFlowTerminal IfcDistributionElement],
          'Civil' => %w[IfcBridge IfcRoad IfcRailway]
        }

        disciplines.map do |discipline_name, types|
          elements = metadata.select { |e| types.include?(e['type']) }

          build_node(
            id: "discipline_#{discipline_name.downcase}",
            name: discipline_name,
            type: 'DisciplineGroup',
            level: 0,
            children_count: elements.size,
            has_children: elements.size > 0,
            icon: icon_for_discipline(discipline_name)
          )
        end.select { |node| node[:children_count] > 0 }
      end

      # Build custom hierarchy (placeholder)
      def build_custom_tree
        # Custom grouping based on user-defined properties
        # Can be extended to group by any property
        build_type_tree
      end

      # Fetch children for a given node
      def fetch_children(node)
        metadata = load_metadata

        case node[:type]
        when 'IfcProject'
          # Get sites
          sites = metadata.select { |e| e['type'] == 'IfcSite' }
          sites.map { |site| build_element_node(site, metadata, 1) }

        when 'IfcSite'
          # Get buildings
          buildings = metadata.select { |e| e['type'] == 'IfcBuilding' }
          buildings.map { |building| build_element_node(building, metadata, 2) }

        when 'IfcBuilding'
          # Get storeys
          storeys = metadata.select { |e| e['type'] == 'IfcBuildingStorey' }
          storeys.map { |storey| build_element_node(storey, metadata, 3) }

        when 'IfcBuildingStorey'
          # Get elements on this storey
          storey_guid = extract_guid_from_node_id(node[:id])
          elements = metadata.select { |e| e['storey'] == storey_guid && e['type'] != 'IfcBuildingStorey' }
          elements.map { |element| build_element_node(element, metadata, 4) }

        when 'TypeGroup'
          # Get all elements of this type
          type = node[:name]
          elements = metadata.select { |e| e['type'] == type }
          elements.map { |element| build_element_node(element, metadata, 1) }

        when 'DisciplineGroup'
          # Get all elements in this discipline
          discipline_name = node[:name]
          types = discipline_types[discipline_name]
          elements = metadata.select { |e| types.include?(e['type']) }

          # Group by type within discipline
          types.select { |type| elements.any? { |e| e['type'] == type } }.map do |type|
            build_node(
              id: "type_#{type}",
              name: type,
              type: 'TypeGroup',
              level: 1,
              children_count: elements.count { |e| e['type'] == type },
              has_children: true,
              icon: icon_for_type(type)
            )
          end

        else
          # Leaf node, no children
          []
        end
      end

      # Build a tree node
      def build_node(attributes)
        {
          id: attributes[:id],
          name: attributes[:name],
          type: attributes[:type],
          guid: attributes[:guid],
          level: attributes[:level],
          children_count: attributes[:children_count] || 0,
          has_children: attributes[:has_children] || false,
          visible: attributes.fetch(:visible, true),
          selected: attributes.fetch(:selected, false),
          icon: attributes[:icon] || 'default',
          metadata: attributes[:metadata] || {}
        }
      end

      # Build element node from metadata
      def build_element_node(element, all_metadata, level)
        children_count = count_element_children(element, all_metadata)

        build_node(
          id: "element_#{element['guid']}",
          name: element['name'] || "#{element['type']}-#{element['guid'][0..7]}",
          type: element['type'],
          guid: element['guid'],
          level: level,
          children_count: children_count,
          has_children: children_count > 0,
          icon: icon_for_type(element['type']),
          metadata: {
            storey: element['storey'],
            discipline: infer_discipline(element['type'])
          }
        )
      end

      # Count children of a node
      def count_children(element, all_metadata, hierarchy_type)
        case hierarchy_type
        when 'spatial'
          case element['type']
          when 'IfcProject'
            all_metadata.count { |e| e['type'] == 'IfcSite' }
          when 'IfcSite'
            all_metadata.count { |e| e['type'] == 'IfcBuilding' }
          when 'IfcBuilding'
            all_metadata.count { |e| e['type'] == 'IfcBuildingStorey' }
          when 'IfcBuildingStorey'
            all_metadata.count { |e| e['storey'] == element['guid'] && e['type'] != 'IfcBuildingStorey' }
          else
            0
          end
        else
          0
        end
      end

      # Count children for an element
      def count_element_children(element, all_metadata)
        # Elements can have nested elements (e.g., windows in walls)
        all_metadata.count { |e| e['parent_guid'] == element['guid'] }
      end

      # Find a node by ID
      def find_node(node_id)
        # Parse node_id to determine type and GUID
        parts = node_id.split('_')
        node_type = parts[0]
        identifier = parts[1..-1].join('_')

        metadata = load_metadata

        case node_type
        when 'project', 'element'
          element = metadata.find { |e| e['guid'] == identifier }
          return nil unless element

          build_element_node(element, metadata, 0)

        when 'type'
          build_node(
            id: node_id,
            name: identifier,
            type: 'TypeGroup',
            level: 0,
            children_count: metadata.count { |e| e['type'] == identifier },
            has_children: true,
            icon: icon_for_type(identifier)
          )

        when 'discipline'
          discipline_name = identifier.capitalize
          types = discipline_types[discipline_name]
          elements = metadata.select { |e| types.include?(e['type']) }

          build_node(
            id: node_id,
            name: discipline_name,
            type: 'DisciplineGroup',
            level: 0,
            children_count: elements.size,
            has_children: true,
            icon: icon_for_discipline(discipline_name)
          )

        else
          nil
        end
      end

      # Load metadata from cache or database
      def load_metadata
        metadata_cache_key = "bim:model:#{@ifc_model.id}:metadata"

        Rails.cache.fetch(metadata_cache_key, expires_in: CACHE_TTL) do
          if @ifc_model.ifc_model_metadata
            @ifc_model.ifc_model_metadata.metadata_json || []
          else
            # Extract from XKT file if metadata not stored
            extract_metadata_from_xkt
          end
        end
      end

      # Extract metadata from XKT file (fallback)
      def extract_metadata_from_xkt
        # This would parse the XKT file and extract element metadata
        # For now, return empty array
        Rails.logger.warn "No metadata found for model #{@ifc_model.id}, returning empty tree"
        []
      end

      # Search by name
      def search_by_name(metadata, query)
        query_lower = query.downcase

        metadata.select do |element|
          name = element['name'] || element['type'] || ''
          name.downcase.include?(query_lower)
        end.map do |element|
          {
            id: "element_#{element['guid']}",
            name: element['name'] || element['type'],
            type: element['type'],
            guid: element['guid'],
            level: element['storey'],
            match_type: 'name'
          }
        end
      end

      # Icon mapping for IFC types
      def icon_for_type(ifc_type)
        icons = {
          'IfcProject' => 'project',
          'IfcSite' => 'map-marker',
          'IfcBuilding' => 'building',
          'IfcBuildingStorey' => 'layers',
          'IfcWall' => 'square',
          'IfcDoor' => 'door-open',
          'IfcWindow' => 'window',
          'IfcSlab' => 'minus',
          'IfcRoof' => 'home',
          'IfcStair' => 'stairs',
          'IfcColumn' => 'grip-vertical',
          'IfcBeam' => 'grip-horizontal',
          'IfcRailing' => 'border-style',
          'IfcFurnishingElement' => 'couch',
          'IfcFlowSegment' => 'pipe',
          'IfcFlowFitting' => 'shapes',
          'IfcFlowTerminal' => 'outlet'
        }

        icons[ifc_type] || 'cube'
      end

      # Icon mapping for disciplines
      def icon_for_discipline(discipline)
        icons = {
          'Architecture' => 'building',
          'Structure' => 'th',
          'MEP' => 'cogs',
          'Civil' => 'road'
        }

        icons[discipline] || 'folder'
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

      # Discipline type mappings
      def discipline_types
        {
          'Architecture' => %w[IfcWall IfcDoor IfcWindow IfcSlab IfcRoof IfcStair IfcRailing IfcCurtainWall],
          'Structure' => %w[IfcBeam IfcColumn IfcFooting IfcPile IfcReinforcingBar IfcTendon],
          'MEP' => %w[IfcFlowSegment IfcFlowFitting IfcFlowTerminal IfcDistributionElement],
          'Civil' => %w[IfcBridge IfcRoad IfcRailway]
        }
      end

      # Extract GUID from node ID
      def extract_guid_from_node_id(node_id)
        node_id.split('_', 2)[1]
      end
    end
  end
end
