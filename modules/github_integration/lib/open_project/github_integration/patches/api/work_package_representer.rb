module OpenProject::GithubIntegration
  module Patches
    module API
      module WorkPackageRepresenter
        module_function

        def extension
          ->(*) do
            link :github,
                uncacheable: true do
              next unless represented.project.module_enabled?(:github) && current_user.allowed_to?(:show_github_content, represented.project)

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
