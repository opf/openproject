# frozen_string_literal: true

module WorkPackage::Automatable
  extend ActiveSupport::Concern

  included do
    def automations(user)
      @automations = Automation
                     .available_conditions
                     .inject(Automation.all) do |scope, condition|
        scope.merge(condition.automation_scope(self, user))
      end
    end

    # API compatibility for /api/v3/custom_actions
    def custom_actions(user)
      automations(user)
    end
  end
end
