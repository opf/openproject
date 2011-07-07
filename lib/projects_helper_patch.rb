module ProjectIssueStatus
  module ProjectHelperPatch
    ProjectsHelper.module_eval do
      def project_settings_tabs_with_project_issue_statuses
        project_settings_tabs_without_project_issue_statuses <<
          {:name => 'project_issue_statuses', :action => :manage_project_activities,
          :partial => 'projects/settings/project_issue_statuses',
          :label => 'backlogs.backlog_settings'}
      end
      alias_method_chain :project_settings_tabs, :project_issue_statuses
    end
  end
end