module Bim
  module IfcModels
    class IfcConversionJob < ::ApplicationJob
      queue_as :ifc_conversion

      ##
      # Run the conversion of IFC to
      def perform(ifc_model)
        result = ViewConverterService.new(ifc_model).call

        unless result.success?
          errors = result.errors.full_messages.join(". ")
          Rails.logger.error "Failed to convert IFC model #{ifc_model.inspect}: #{errors}"
        end
      end
    end
  end
end
