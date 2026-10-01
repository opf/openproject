# frozen_string_literal: true

# Registers the Control Center login hook (lib/herfy/control_center_hook.rb) and,
# when HERFY_CC_ISSUER / HERFY_CC_CLIENT_ID / HERFY_CC_CLIENT_SECRET are set,
# keeps the OIDC provider in step with them on every boot (no manual rake step).
Rails.application.config.to_prepare do
  Herfy::ControlCenterHook
end

Rails.application.config.after_initialize do
  next unless Herfy::ControlCenter::Provisioner.configured?

  begin
    Herfy::ControlCenter::Provisioner.call(force: false)
  rescue StandardError => e
    Rails.logger.error("[herfy] control center provider provisioning failed: #{e.class}: #{e.message}")
  end
end
