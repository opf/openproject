module Exports
  module Formatters
    class CustomField < Default
      ##
      # Checks if this column is applicable for this column
      def self.apply?(attribute)
        attribute.start_with?('cf_')
      end

      ##
      # Takes a WorkPackage and an attribute and returns the value to be exported.
      def retrieve_value(object)
        return '' if custom_field.nil?

        object.formatted_custom_value_for(custom_field)
      end

      ##
      # Finds a custom field from the attribute identifier
      def custom_field
        unless defined?(@custom_field)
          @custom_field = ::CustomField.find_by(id: attribute.to_s.sub('cf_', '').to_i)
        end

        @custom_field
      end
    end
  end
end
