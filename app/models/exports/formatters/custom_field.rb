module Exports
  module Formatters
    class CustomField < Default
      def self.apply?(attribute)
        attribute.start_with?('cf_')
      end

      ##
      # Takes a WorkPackage and an attribute and returns the value to be exported.
      def retrieve_value(object)
        custom_field = find_custom_field(object)
        return '' if custom_field.nil?

        object.formatted_custom_value_for(custom_field)
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
