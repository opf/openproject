module OpenProject::GithubIntegration::Patches
  module API::V3::AdditionalWorkPackageTabs
    def additional_work_package_tabs
      if represented.project.module_enabled?(:github) && current_user.allowed_to?(:show_github_content, represented.project)
        super + [:github]
      else
        super
      end
    end
  end
end
