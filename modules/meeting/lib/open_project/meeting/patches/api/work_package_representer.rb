module OpenProject::Meeting
  module Patches
    module API
      module WorkPackageRepresenter
        module_function

        def extension
          ->(*) do
            link :meetings,
                 cache_if: -> { current_user.allowed_to?(:view_meetings, represented.project) } do
              {
                href: "#{work_package_path(id: represented.id)}/tabs/meetings",
                title: "meetings"
              }
            end
          end
        end
      end
    end
  end
end
