require_dependency 'versions_controller'

module OpenProject::Backlogs::Patches::VersionsControllerPatch
  def self.included(base)
    base.class_eval do
      unloadable

      include VersionSettingsHelper
      helper :version_settings

      # Find project explicitly on update and edit
      skip_before_filter :find_project_from_association, :only => [:edit, :update]
      skip_before_filter :find_model_object, :only => [:edit, :update]
      prepend_before_filter :find_project_and_version, :only => [:edit, :update]

      before_filter :add_project_to_version_settings_attributes, :only => [:update, :create]

      before_filter :whitelist_update_params, :only => :update

      def whitelist_update_params
        if @project != @version.project
          # Make sure only the version_settings_attributes
          # (column=left|right|none) can be stored when current project does not
          # equal the version project (which is valid in inherited versions)
          if params[:version] and params[:version][:version_settings_attributes]
            params[:version] = { :version_settings_attributes => params[:version][:version_settings_attributes] }
          else
            params[:version] = {}
          end
        end
      end


      def find_project_and_version
        find_model_object
        if params[:project_id]
          find_project
        else
          find_project_from_association
        end
      end

      # This forces the current project for the nested version settings in order
      # to prevent it from being set through firebug etc. #mass_assignment
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
