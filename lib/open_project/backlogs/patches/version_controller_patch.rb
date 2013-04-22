require_dependency 'versions_controller'

module OpenProject::Backlogs::Patches::VersionsControllerPatch
  def self.included(base)
    base.class_eval do
      unloadable

      include VersionSettingsHelper
      helper :version_settings

      # find project explicitly on update and edit
      skip_before_filter :find_project_from_association, :only => [:edit, :update]
      skip_before_filter :find_model_object, :only => [:edit, :update]
      prepend_before_filter :find_project_and_version, :only => [:edit, :update]

      before_filter :add_project_to_version_settings_attributes, :only => [:update, :create]

      def find_project_and_version
        find_model_object
        if params[:project_id]
          find_project
        else
          find_project_from_association
        end
      end

      # this forces the current project for the nested version settings
      # in order to prevent it from being set through firebug etc. #mass_assignment
      def add_project_to_version_settings_attributes
        if params["version"]["version_settings_attributes"]
          params["version"]["version_settings_attributes"].each do |attr_hash|
            attr_hash["project"] = @project
          end
        end
      end
    end
  end
end

VersionsController.send(:include, OpenProject::Backlogs::Patches::VersionsControllerPatch)
