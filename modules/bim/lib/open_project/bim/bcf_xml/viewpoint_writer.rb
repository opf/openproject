##
# Creates or updates a BCF issue and markup from a work package
module OpenProject::Bim::BcfXml
  class ViewpointWriter < BaseWriter
    attr_reader :viewpoint

    def initialize(viewpoint)
      @viewpoint = viewpoint
      super()
    end

    def to_xml
      doc.to_xml(indent: 2)
    end

    def doc
      @doc ||= begin
        viewpoint_node = fetch(markup_doc, root_node.to_s)

        Nokogiri::XML::Builder.with(viewpoint_node) do |xml|
          components xml

          camera('orthogonal_camera', xml)
          camera('perspective_camera', xml)

          lines xml
          clipping_planes xml
          bitmaps xml
        end

        markup_doc
      end
    end

    protected

    def root_node
      :VisualizationInfo
    end

    def root_node_attributes
      { Guid: viewpoint.uuid }
    end

    def dig_json(*args)
      viewpoint.json_viewpoint.dig(*args)
    end

    def components(xml)
      return unless dig_json('components')

      xml.Components do
        view_setup_hints xml
        selected_components xml
        visibility xml
        coloring xml
      end
    end

    def view_setup_hints(xml)
      return unless (setup_hash = dig_json('components', 'visibility', 'view_setup_hints'))

      xml.ViewSetupHints(camelized(setup_hash))
    end

    def selected_components(xml)
      return unless (selected = dig_json('components', 'selection'))

      xml.Selection do
        selected.each do |comp_hash|
          xml.Component camelized(comp_hash)
        end
      end
    end

    def visibility(xml)
      return unless (visibility_hash = dig_json 'components', 'visibility')

      xml.Visibility(DefaultVisibility: visibility_hash['default_visibility']) do
        exceptions = visibility_hash['exceptions']
        next unless exceptions

        xml.Exceptions do
          Array.wrap(exceptions).each do |comp_hash|
            xml.Component camelized(comp_hash)
          end
        end
      end
    end

    def coloring(xml)
      return unless (colors = dig_json 'components', 'coloring')

      xml.Coloring do
        Array.wrap(colors).each do |color|
          xml.Color Color: color['color'].delete_prefix('#') do
            Array.wrap(color['components']).each do |comp_hash|
              xml.Component camelized(comp_hash)
            end
          end
        end
      end
    end

    def camera(type, xml)
      return unless (camera = dig_json(type))

      xml.send(type.camelize) do
        %w[CameraViewPoint CameraDirection CameraUpVector].each do |entry|
          xml.send(entry) do
            coords = camera[entry.underscore]
            to_xml_coords(coords, xml)
          end
        end
        xml.FieldOfView convert_float(camera['field_of_view'])
      end
    end

    def lines(xml)
      return unless (lines = dig_json 'lines')

      xml.Lines do
        Array.wrap(lines).each do |line|
          xml.Line do
            xml.StartPoint { to_xml_coords(line['start_point'], xml) }
            xml.EndPoint { to_xml_coords(line['end_point'], xml) }
          end
        end
      end
    end

    def clipping_planes(xml)
      return unless (planes = dig_json 'clipping_planes')

      xml.ClippingPlanes do
        Array.wrap(planes).each do |plane|
          xml.ClippingPlane do
            xml.Location { to_xml_coords(plane['location'], xml) }
            xml.Direction { to_xml_coords(plane['direction'], xml) }
          end
        end
      end
    end

    def bitmaps(xml)
      return unless (entries = dig_json 'bitmaps')

      # Bitmaps are rendered flat, whyever that is
      entries.each do |bitmap|
        xml.Bitmaps do
          xml.Bitmap bitmap['bitmap_type'].upcase
          xml.Reference bitmap['bitmap_data']
          xml.Location { to_xml_coords bitmap['location'], xml }
          xml.Normal { to_xml_coords bitmap['normal'], xml }
          xml.Up { to_xml_coords bitmap['up'], xml }
          xml.Height convert_float(bitmap['height'])
        end
      end
    end

    ##
    # Helper to transform a hash into camelized keys
    def camelized(hash)
      hash.transform_keys do |key|
        # `camelize` uses the inflections of ActiveSupport. There we defined inflections for `IFC`. However, here we
        # don't want that applied here. `ifc_foo` shall be converted to `IfcFoo` and not to `IFCFoo`.
        key.camelize.gsub(/IFC/, 'Ifc')
      end
    end

    ##
    # Convert a float to BCF format that strips
    # insignificant zeros
    def convert_float(val)
      val.to_s.gsub(/(\.)0+$/, '')
    end

    ##
    # Helper to render X,Y,Z hash as set of nodes
    def to_xml_coords(hash, xml)
      hash.each do |key, val|
        xml.send(key.to_s.upcase, convert_float(val))
      end
    end
  end
end
