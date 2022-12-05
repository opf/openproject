module OpenProject::GitlabIntegration
  module Patches
    module WorkPackagePatch
      extend ActiveSupport::Concern

      included do
        has_and_belongs_to_many :gitlab_merge_requests
      end
    end
  end
end

::WorkPackage.include OpenProject::GitlabIntegration::Patches::WorkPackagePatch
