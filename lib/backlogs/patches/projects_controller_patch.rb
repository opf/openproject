require_dependency 'projects_controller'

module Backlogs::Patches::ProjectsControllerPatch
  def self.included(base)
    base.class_eval do
      include InstanceMethods

      alias_method_chain :settings, :backlogs_settings
    end
  end

  module InstanceMethods
    def settings_with_backlogs_settings
      settings_without_backlogs_settings
      @issue_statuses = IssueStatus.all
    end

    def project_issue_statuses
      selected_statuses = (params[:issue_statuses] || []).map do |issue_status|
        IssueStatus.find(issue_status[:status_id].to_i)
      end.compact

      @project.issue_statuses = selected_statuses
      @project.save!

      flash[:notice] = l(:notice_successful_update)

      redirect_to :action => 'settings', :id => @project, :tab => 'backlogs_settings'
    end

    def rebuild_positions
      @project.rebuild_positions
      flash[:notice] = l('backlogs.positions_rebuilt_successfully')

      redirect_to :action => 'settings', :id => @project, :tab => 'backlogs_settings'
    rescue ActiveRecord::ActiveRecordError
      flash[:error] = l('backlogs.positions_could_not_be_rebuilt')

      logger.error("Tried to rebuild positions for project #{@project.identifier.inspect} but could not...")
      logger.error($!)
      logger.error($@)

      redirect_to :action => 'settings', :id => @project, :tab => 'backlogs_settings'
    end
  end
end

ProjectsController.send(:include, Backlogs::Patches::ProjectsControllerPatch)
