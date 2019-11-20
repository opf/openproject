module OpenProject::Bcf
  module BcfJson
    class ViewpointMapper
      ROOT_NODE ||= 'VisualizationInfo'.freeze

      attr_reader :resource

      def initialize(viewpoint)
        @resource = viewpoint
      end

      def result
        viewpoint_hash
      end

      def to_json
        viewpoint_hash.to_json
      end

      private

      ##
      # Retrieve the viewpoint hash without root node, if any.
      def viewpoint_hash
        @viewpoint_hash ||= begin
          # Load from XML using activesupport
          hash = Hash.from_xml(resource.viewpoint)
          hash = hash[ROOT_NODE] if hash.key?(ROOT_NODE)

          # Perform destructive transformations
          transformations.each do |m|
            send(m, hash)
          end

          hash
        end
      end

      def transformations
        %i[
          remove_keys
          transform_keys
          transform_perspective_camera
          transform_orthogonal_camera
          transform_lines
          transform_clipping_planes
          transform_selections
          transform_coloring
          transform_visibility
        ]
      end

      def remove_keys(hash)
        hash.delete 'xmlns:xsi'
        hash.delete 'xmlns:xsd'
      end

      def transform_keys(hash)
        # Underscore all keys, will make it easier to reuse more portions of the XML
        hash.deep_transform_keys!(&:underscore)
      end

      ##
      # Transform perspective_camera into json float values
      def transform_orthogonal_camera(hash)
        transform_camera hash, 'orthogonal_camera'
      end

      ##
      # Transform orthogonal_camera into json float values
      def transform_perspective_camera(hash)
        transform_camera hash, 'perspective_camera'
      end

      def transform_camera(hash, key)
        return unless hash.key?(key)

        hash[key].transform_values! do |v|
          if v.is_a?(Hash)
            v.transform_values!(&:to_f)
          else
            v.to_f
          end
        end
      end

      def transform_lines(hash)
        return unless hash.key?('lines')

        hash['lines'] = hash['lines']['line'].map! do |line|
          line.deep_transform_values!(&:to_f)
        end
      end

      def transform_clipping_planes(hash)
        return unless hash.key?('clipping_planes')

        hash['clipping_planes'] = hash['clipping_planes']['clipping_plane'].map! do |plane|
          plane.deep_transform_values!(&:to_f)
        end
      end

      ##
      # Move selections up the tree from the nested XML node
      def transform_selections(hash)
        selections = hash.dig('components', 'selection', 'component')
        return unless selections

        hash['components']['selection'] = selections
      end

      ##
      # Move coloring up the tree from the nested XML node
      def transform_coloring(hash)
        colors = hash.dig('components', 'coloring', 'color')
        return unless colors

        # avoid Array(colors) since that deconstructs the array
        colors = [colors] unless colors.is_a?(Array)

        hash['components']['coloring'] = colors.map do |entry|
          # Prepend hash for hex color
          entry['color'] = "##{entry['color']}"
          entry
        end
      end

      def transform_visibility(hash)
        visibility = hash.dig('components', 'visibility')
        return unless visibility

        visibility['default_visibility'] = visibility['default_visibility'] == 'true'

        # Hoist exceptions components up from the nested XML node
        exceptions = visibility.dig('exceptions', 'component')
        visibility['exceptions'] = Array(exceptions) if exceptions

        # Move view_setup_hints
        view_setup_hints = hash.dig('components', 'view_setup_hints')
        visibility['view_setup_hints'] = view_setup_hints.transform_values { |val| val == 'true' }

        # Remove the old node
        hash['components'].delete('view_setup_hints')
      end
    end
  end
end
