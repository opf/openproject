module FormFields
  module Primerized
    class FormField < FormFields::FormField
      def property_name
        if property.is_a? CustomField
          property.attribute_name(:kebab_case)
        else
          property.to_s
        end
      end
    end
  end
end
