# frozen_string_literal: true

# Registers the Control Center login hook (see lib/herfy/control_center_hook.rb).
Rails.application.config.to_prepare do
  Herfy::ControlCenterHook
end
