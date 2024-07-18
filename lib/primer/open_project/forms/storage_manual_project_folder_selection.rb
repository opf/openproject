module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class StorageManualProjectFolderSelection < Primer::Forms::BaseComponent
        include AngularHelper

        delegate :builder, :form, to: :@input

        def initialize(input:, project_storage:, storage_login_button_options:, last_project_folders: {},
                       wrapper_data_attributes: {})
          super()
          @input = input
          @project_storage = project_storage
          @last_project_folders = last_project_folders
          @storage_login_button_options = storage_login_button_options
          @wrapper_data_attributes = derive_wrapper_data_attributes(wrapper_data_attributes)
        end

        private

        def derive_wrapper_data_attributes(options)
          options.reverse_merge(
            "application-target": "dynamic",
            controller: "project-storage-form",
            "project-storage-form-folder-mode-value": @project_storage.project_folder_mode,
            "project-storage-form-placeholder-folder-name-value": I18n.t(:"storages.label_no_selected_folder"),
            "project-storage-form-not-logged-in-validation-value": I18n.t(:"storages.instructions.not_logged_into_storage"),
            "project-storage-form-last-project-folders-value": @last_project_folders,
            "project-storage-form-target": "projectFolderSection"
          )
        end

        def storage_oauth_access_granted?
          OAuthClientToken
            .exists?(user: User.current, oauth_client: @project_storage.storage.oauth_client)
        end
      end
    end
  end
end
