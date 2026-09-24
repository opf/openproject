# frozen_string_literal: true

module WorkPackages
  module TrashFeature
    module_function

    def enabled?
      EnterpriseToken.allows_to?(:work_package_trash) ||
        ActiveModel::Type::Boolean.new.cast(ENV.fetch("OPENPROJECT_ENABLE_WORK_PACKAGE_TRASH", false))
    end
  end
end
