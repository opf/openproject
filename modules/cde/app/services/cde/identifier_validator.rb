# frozen_string_literal: true

module Cde
  class IdentifierValidator
    class << self
      def valid?(identifier, project_id = nil)
        return false if identifier.blank?

        # Check format against conventions
        return false unless identifier.match?(Cde::Conventions.container_id_validator)

        # Check uniqueness if project_id provided
        if project_id.present?
          !Cde::Container.exists?(identifier: identifier, project_id: project_id)
        else
          true
        end
      end

      def generate(container_type, project_id, user)
        project = Project.find(project_id)
        conventions = Cde::Conventions.config

        # Generate identifier based on project conventions
        identifier = generate_identifier(
          project: project,
          container_type: container_type,
          conventions: conventions
        )

        identifier
      end

      private

      def generate_identifier(project:, container_type:, conventions:)
        # Implementation based on project naming conventions
        # This is a simplified version - actual implementation would depend on project requirements
        project_code = project.identifier.upcase
        container_type_code = container_type.to_s.upcase
        timestamp = Time.now.strftime('%Y%m%d%H%M%S')
        random_code = SecureRandom.hex(2).upcase

        "#{project_code}-#{container_type_code}-#{timestamp}-#{random_code}"
      end
    end
  end
end
