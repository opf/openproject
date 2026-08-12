# frozen_string_literal: true

module Cde
  class PublicationGate
    class PublicationError < StandardError; end

    class << self
      def check(container)
        errors = []

        # Check mandatory metadata
        errors << 'Mandatory metadata incomplete' unless metadata_complete?(container)

        # Check identifier validity
        errors << 'Identifier invalid' unless identifier_valid?(container)

        # Check suitability assignment
        errors << 'Suitability not assigned' unless suitability_assigned?(container)

        # Check approvals (placeholder - actual approval logic in Slice 6)
        errors << 'Required approvals incomplete' unless approvals_complete?(container)

        return errors.empty? ? true : errors
      end

      def enforce(container, user: nil)
        errors = check(container)
        raise PublicationError, errors.join('; ') if errors.any?

        # Proceed with publication
        container.publish!(user: user)
      end

      private

      def metadata_complete?(container)
        mandatory_fields = Cde::Conventions.mandatory_metadata_fields
        container.metadata_entries.none? { |m| mandatory_fields.any? { |f| m.send(f).blank? } }
      end

      def identifier_valid?(container)
        Cde::IdentifierValidator.valid?(container.identifier, container.project_id)
      end

      def suitability_assigned?(container)
        container.suitability.present?
      end

      def approvals_complete?(container)
        # Implementation depends on approval workflow (Slice 6)
        # For now, return true as placeholder
        true
      end
    end
  end
end
