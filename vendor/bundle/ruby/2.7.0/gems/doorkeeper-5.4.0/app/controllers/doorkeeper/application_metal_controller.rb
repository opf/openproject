# frozen_string_literal: true

module Doorkeeper
  class ApplicationMetalController <
    Doorkeeper.config.resolve_controller(:base_metal)
    include Helpers::Controller

    before_action :enforce_content_type,
                  if: -> { Doorkeeper.config.enforce_content_type }

    ActiveSupport.run_load_hooks(:doorkeeper_metal_controller, self)
  end
end
