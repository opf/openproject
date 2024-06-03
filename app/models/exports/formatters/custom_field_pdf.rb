module Exports
  module Formatters
    class CustomFieldPdf < CustomField
      def self.apply?(attribute, export_format)
        export_format == :pdf && attribute.start_with?("cf_")
      end

      ##
      # Print the value meant for export.
      #
      # - For boolean values, use the Yes/No formatting for the PDF
      #   treat nil as false
      # - For long text values, output the plain value
      def format_for_export(object, custom_field)
        case custom_field.field_format
        when "bool"
          value = object.typed_custom_value_for(custom_field)
          value ? I18n.t(:general_text_Yes) : I18n.t(:general_text_No)
        when "text"
          object.typed_custom_value_for(custom_field)
        else
          object.formatted_custom_value_for(custom_field)
        end
      end
    end
  end
end
