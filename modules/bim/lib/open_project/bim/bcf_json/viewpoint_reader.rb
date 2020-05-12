require 'bigdecimal'

module OpenProject::Bim
  module BcfJson
    class ViewpointReader
      ROOT_NODE ||= 'VisualizationInfo'.freeze

      attr_reader :uuid, :xml

      def initialize(uuid, xml)
        @uuid = uuid
        @xml = xml
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
          hash = Hash.from_xml(xml)
          hash = hash[ROOT_NODE] if hash[ROOT_NODE]

          # Perform destructive transformations
          transformations.each do |method_name|
            send(method_name, hash)
          end

          hash
        end
      end

      def transformations
        %i[
          remove_keys
          transform_keys
          set_uuid
          transform_perspective_camera
          transform_orthogonal_camera
          transform_lines
          transform_clipping_planes
          transform_bitmaps
          transform_selections
          transform_coloring
          transform_visibility
        ]
      end

      def remove_keys(hash)
        hash.delete 'xmlns:xsi'
        hash.delete 'xmlns:xsd'
        hash.delete 'VisualizationInfo' unless hash['VisualizationInfo']
      end

      def set_uuid(hash)
        hash['guid'] = uuid
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
        return unless hash[key]

        hash[key].transform_values! do |v|
          if v.is_a?(Hash)
            v.transform_values! { |val| to_numeric(val) }
          else
            to_numeric(v)
          end
        end
      end

      def transform_lines(hash)
        return unless hash['lines']

        hash['lines'] = [hash['lines']['line']].flatten(1).map! do |line|
          line.deep_transform_values! { |val| to_numeric(val) }
        end
      end

      def transform_clipping_planes(hash)
        return unless hash['clipping_planes']

        hash['clipping_planes'] = [hash['clipping_planes']['clipping_plane']].flatten(1).map! do |plane|
          plane.deep_transform_values! { |val| to_numeric(val) }
        end
      end

      def transform_bitmaps(hash)
        return unless hash['bitmaps']

        # Bitmaps can be multiple items within the root bitmaps node
        # this is different from the other entries
        # https://github.com/buildingSMART/BCF-XML/pull/44/files
        bitmaps = Array.wrap(hash['bitmaps'])

        hash['bitmaps'] = bitmaps.map! do |bitmap|
          bitmap['bitmap_type'] = bitmap.delete('bitmap').downcase
          bitmap['bitmap_data'] = bitmap.delete('reference')
          bitmap['height'] = to_numeric(bitmap['height'])

          %w[location normal up].each do |key|
            next unless bitmap.key?(key)

            # Transform all coordinates to floats
            bitmap[key].transform_values! { |val| to_numeric(val) }
          end

          bitmap
        end
      end

      ##
      # Move selections up the tree from the nested XML node
      def transform_selections(hash)
        return unless (selections = hash.dig('components', 'selection', 'component'))

        # Ensure selections are an array
        selections = Array.wrap(selections)

        # Skip any components that have no guid
        selections.select! { |item| item['ifc_guid'] }

        hash['components']['selection'] = selections
      end

      ##
      # Move coloring up the tree from the nested XML node
      def transform_coloring(hash)
        return unless (colors = hash.dig('components', 'coloring', 'color'))

        # avoid Array(colors) since that deconstructs the array
        colors = Array.wrap(colors)

        hash['components']['coloring'] = colors.map do |entry|
          # Prepend hash for hex color
          entry['color'] = "##{entry['color']}"

          # Fix items name
          entry['components'] = entry.delete('component')
          entry
        end
      end

      def transform_visibility(hash)
        return unless (visibility = hash.dig('components', 'visibility'))

        visibility['default_visibility'] = visibility['default_visibility'] == 'true'

        # Hoist exceptions components up from the nested XML node
        exceptions = visibility.dig('exceptions', 'component')
        visibility['exceptions'] = Array(exceptions) if exceptions

        # Move view_setup_hints
        view_setup_hints = hash.dig('components', 'view_setup_hints')
        visibility['view_setup_hints'] = view_setup_hints.transform_values { |val| val == 'true' } if view_setup_hints

        # Remove the old node
        hash['components'].delete('view_setup_hints')
      end

      def to_numeric(anything)
        num = BigDecimal(anything.to_s)
        if num.frac == 0
          num.to_i
        else
          num.to_f
        end
      end
    end
  end
end
