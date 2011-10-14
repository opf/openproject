require_dependency 'versions_controller'

module RedmineBacklogs::Patches::VersionsControllerPatch
  def self.included(base)
    base.class_eval do
      unloadable

      include VersionSettingsHelper
      helper :version_settings

      # find project explicitly on update
      filter_chain.detect { |m| m.method == :find_project_from_association }.options[:except] << "update"
      filter_chain.detect { |m| m.method == :find_project }.options[:only] << "update"
    end
  end
end

VersionsController.send(:include, RedmineBacklogs::Patches::VersionsControllerPatch)
