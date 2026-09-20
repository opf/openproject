# frozen_string_literal: true

module WorkPackages
  module TrashFeature
    ENABLED_PLANS = %i[premium corporate].freeze

    module_function

    def enabled?
      EnterpriseToken.allows_to?(:work_package_trash) ||
        EnterpriseToken.active_tokens.any? { |token| token.plan.to_sym.in?(ENABLED_PLANS) }
    end
  end
end
