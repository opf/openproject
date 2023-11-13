module Exports
  module Formatters
    class CustomField < Default
      def self.apply?(attribute, _export_format)
        attribute.start_with?('cf_')
      end

      ##
      # Takes a WorkPackage and an attribute and returns the value to be exported.
      def retrieve_value(object)
        custom_field = find_custom_field(object)
        return '' if custom_field.nil?

        format_for_export(object, custom_field)
      end

      ##
      # Print the value meant for export.
      #
      # - For boolean values, don't use the Yes/No formatting for the UI
      #   treat nil as false
      # - For long text values, output the plain value
      def format_for_export(object, custom_field)
        case custom_field.field_format
        when 'bool'
          value = object.typed_custom_value_for(custom_field)
          value == nil ? false : value
        when 'text'
          object.typed_custom_value_for(custom_field)
        else
          object.formatted_custom_value_for(custom_field)
        end
      end

      ##
      # Finds a custom field from the attribute identifier
      def find_custom_field(object)
        id = attribute.to_s.sub('cf_', '').to_i
        object.available_custom_fields.detect { |cf| cf.id == id }
      end
    end
  end
end
