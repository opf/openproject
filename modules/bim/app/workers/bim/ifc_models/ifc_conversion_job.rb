module Bim
  module IfcModels
    class IfcConversionJob < ::ApplicationJob
      queue_as :ifc_conversion

      ##
      # Run the conversion of IFC to
      def perform(ifc_model)
        return retry_job(wait: 1.minute) if attachment_missing?(ifc_model)

        User.system.run_given do
          result = ViewConverterService.new(ifc_model).call

          unless result.success?
            errors = result.errors.full_messages.join(". ")
            Rails.logger.error "Failed to convert IFC model #{ifc_model.inspect}: #{errors}"
          end
        end
      end

      private

      ##
      # Is the ifc attachment of the model ready for consumption?
      def attachment_missing?(ifc_model)
        !ifc_model.ifc_attachment_ready?
      end
    end
  end
end
