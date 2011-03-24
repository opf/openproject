module Backlogs
  module VersionsControllerPatch
    def self.included(base)
      base.class_eval do
        unloadable
        include VersionSettingsHelper
        helper :version_settings
      end
    end
  end
end

VersionsController.send(:include, Backlogs::VersionsControllerPatch)