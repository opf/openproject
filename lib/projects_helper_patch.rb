module Backlogs
  module ProjectHelperPatch
    def self.included(base)
      base.module_eval do
        def project_settings_tabs_with_project_issue_statuses
          project_settings_tabs_without_project_issue_statuses.tap do |settings|
            if @project.module_enabled? 'backlogs'
              settings << {
                :name => 'project_issue_statuses',
                :action => :manage_project_activities,
                :partial => 'projects/settings/project_issue_statuses',
                :label => 'backlogs.backlog_settings'
              }
            end
          end
        end

        alias_method_chain :project_settings_tabs, :project_issue_statuses
      end
    end
  end
end

ProjectsHelper.send(:include, Backlogs::ProjectHelperPatch)
