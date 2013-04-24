require_dependency 'projects_controller'

module OpenProject::Costs::Patches::ProjectsControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      before_filter :own_total_hours, :only => [:show]
    end

  end

  module InstanceMethods
    def own_total_hours
      if User.current.allowed_to?(:view_own_time_entries, @project)
        cond = @project.project_condition(Setting.display_subprojects_issues?)
        @total_hours = TimeEntry.visible.sum(:hours, :include => :project, :conditions => cond).to_f
      end
    end
  end
end

ProjectsController.send(:include, OpenProject::Costs::Patches::ProjectsControllerPatch)
