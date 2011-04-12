module Backlogs
  module VersionsControllerPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        unloadable
        include VersionSettingsHelper
        helper :version_settings

        find_project_explicitly_on_update
      end
    end

    module ClassMethods
      private
      def find_project_explicitly_on_update
        filter_chain.detect{|m| m.method == :find_project_from_association }.options[:except] << "update"
        filter_chain.detect{|m| m.method == :find_project }.options[:only] << "update"
      end
    end
  end
end

VersionsController.send(:include, Backlogs::VersionsControllerPatch)