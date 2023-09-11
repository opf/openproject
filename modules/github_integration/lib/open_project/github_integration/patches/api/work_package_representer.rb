module OpenProject::GithubIntegration
  module Patches
    module API
      module WorkPackageRepresenter
        module_function

        def extension
          ->(*) do
            link :github,
                 cache_if: -> { current_user.allowed_to?(:show_github_content, represented) } do
              {
                href: "#{work_package_path(id: represented.id)}/tabs/github",
                title: "github"
              }
            end

            link :github_pull_requests do
              {
                href: api_v3_paths.github_pull_requests_by_work_package(represented.id),
                title: "GitHub pull requests"
              }
            end
          end
        end
      end
    end
  end
end
