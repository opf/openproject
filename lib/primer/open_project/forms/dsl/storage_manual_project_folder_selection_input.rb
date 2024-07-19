# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        class StorageManualProjectFolderSelectionInput < Primer::Forms::Dsl::Input
          attr_reader :name, :label

          def initialize(name:, label:, project_storage:, last_project_folders: {}, storage_login_button_options: {},
                         select_folder_button_options: {}, wrapper_arguments: {}, **system_arguments)
            @name = name
            @label = label
            @project_storage = project_storage
            @last_project_folders = last_project_folders
            @storage_login_button_options = storage_login_button_options
            @select_folder_button_options = select_folder_button_options
            @wrapper_arguments = wrapper_arguments

            super(**system_arguments)
          end

          def to_component
            StorageManualProjectFolderSelection.new(
              input: self,
              project_storage: @project_storage,
              last_project_folders: @last_project_folders,
              storage_login_button_options: @storage_login_button_options,
              select_folder_button_options: @select_folder_button_options,
              wrapper_arguments: @wrapper_arguments
            )
          end

          def type
            :storage_manual_project_folder_selection
          end

          def focusable?
            true
          end
        end
      end
    end
  end
end
