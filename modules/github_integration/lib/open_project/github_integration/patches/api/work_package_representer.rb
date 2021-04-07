module OpenProject::GithubIntegration
  module Patches
    module API
      module WorkPackageRepresenter
        module_function

        def extension
          ->(*) do
            link :github,
                 cache_if: -> { current_user.allowed_to?(:show_github_content, represented.project) } do
              {
                href: "#{work_package_path(id: represented.id)}/tabs/github",
                title: "github"
              }
            end
          end
        end
      end
    end
  end
end
