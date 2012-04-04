require_dependency 'versions_controller'

module Backlogs::Patches::VersionsControllerPatch
  def self.included(base)
    base.class_eval do
      unloadable

      include VersionSettingsHelper
      helper :version_settings

      # find project explicitly on update
      filter_chain.detect { |m| m.method == :find_project_from_association }.options[:except] << "update"
      filter_chain.detect { |m| m.method == :find_project }.options[:only] << "update"

      before_filter :assign_project_to_version_settings, :only => [:create, :update]

      protected

      def assign_project_to_version_settings
        if params[:version] && params[:version][:version_settings_attributes]
          params[:version][:version_settings_attributes].each do |attributes|
            attributes[:project] = @project
            attributes.delete(:project_id)
          end
        end
      end
    end
  end
end

VersionsController.send(:include, Backlogs::Patches::VersionsControllerPatch)
