module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class StorageManualProjectFolderSelection < Primer::Forms::BaseComponent
        include AngularHelper

        delegate :builder, :form, to: :@input

        def initialize(input:, project_storage:, last_project_folders: {},
                       storage_login_button_options: {}, select_folder_button_options: {}, wrapper_arguments: {})
          super()
          @input = input

          @project_storage = project_storage
          @last_project_folders = last_project_folders

          @storage_login_button_options = storage_login_button_options
          @selected_folder_label_options = select_folder_button_options.delete(:selected_folder_label_options) { {} }
          @select_folder_button_options = select_folder_button_options

          @wrapper_data_attributes = wrapper_arguments.delete(:data) { {} }
          @wrapper_classes = wrapper_arguments.delete(:classes) { [] }
        end

        private

        def storage_oauth_access_granted?
          OAuthClientToken
            .exists?(user: User.current, oauth_client: @project_storage.storage.oauth_client)
        end
      end
    end
  end
end
