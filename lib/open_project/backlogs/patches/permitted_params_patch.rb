require_dependency 'permitted_params'

module OpenProject::Backlogs::Patches::PermittedParamsPatch
  def self.included(base)

    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :new_work_package, :backlogs
      alias_method_chain :update_work_package, :backlogs
    end
  end

  module InstanceMethods
    def new_work_package_with_backlogs(args = {})
      permitted_params = new_work_package_without_backlogs(args)

      backlogs_params = params.require(:work_package).permit(:story_points, :remaining_hours)
      permitted_params.merge!(backlogs_params)

      permitted_params
    end
    def update_work_package_with_backlogs(args = {})

      permitted_params = update_work_package_without_backlogs(args)

      backlogs_params = params.require(:work_package).permit(:story_points, :remaining_hours)
      permitted_params.merge!(backlogs_params)

      permitted_params
    end
  end
end
PermittedParams.send(:include, OpenProject::Backlogs::Patches::PermittedParamsPatch)
