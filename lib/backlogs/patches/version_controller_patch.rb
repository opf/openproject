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

      before_filter :add_project_to_version_settings_attributes, :only => [:update, :create]

      def add_project_to_version_settings_attributes
        params["version"]["version_settings_attributes"].each do |h|
          h["project"] = @project
        end
      end
    end
  end
end

VersionsController.send(:include, Backlogs::Patches::VersionsControllerPatch)
