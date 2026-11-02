# frozen_string_literal: true

module OpenProject::TestManagement
  module Patches
    module API
      # Adds `_links.testing` to the APIv3 work package. The Angular "Testing"
      # tab is displayable only when this link is present (same pattern as the
      # GitHub and Meetings tabs).
      module WorkPackageRepresenter
        module_function

        def extension
          ->(*) do
            link :testing,
                 cache_if: -> {
                   ::TestManagement::WorkPackageTestingTabController.tab_visible?(current_user, represented)
                 } do
              next if represented.new_record?

              {
                href: "#{work_package_path(id: represented.id)}/tabs/testing",
                title: "testing"
              }
            end
          end
        end
      end
    end
  end
end
