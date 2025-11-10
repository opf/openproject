# frozen_string_literal: true

# Subscribe BIM audit trail service to domain events
Rails.application.config.to_prepare do
  # Subscribe to all BIM domain events for audit logging
  Bim::Services::AuditTrailService.subscribe_to_events!
end
