require_dependency 'projects_helper'

module Backlogs::Patches::ProjectsHelperPatch
  def self.included(base)
    base.module_eval do
      def project_settings_tabs_with_backlogs_settings
        project_settings_tabs_without_backlogs_settings.tap do |settings|
          if @project.module_enabled? 'backlogs'
            settings << {
              :name => 'backlogs_settings',
              :action => :manage_project_activities,
              :partial => 'projects/settings/backlogs_settings',
              :label => 'backlogs.backlog_settings'
            }
          end
        end
      end

      alias_method_chain :project_settings_tabs, :backlogs_settings
    end
  end
end

ProjectsHelper.send(:include, Backlogs::Patches::ProjectsHelperPatch)
