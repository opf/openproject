# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        class StorageManualProjectFolderSelectionInput < Primer::Forms::Dsl::Input
          attr_reader :name, :label

          def initialize(name:, label:, project_storage:, storage_login_button_options:, last_project_folders: {},
                         wrapper_data_attributes: {}, **system_arguments)
            @name = name
            @label = label
            @project_storage = project_storage
            @last_project_folders = last_project_folders
            @wrapper_data_attributes = wrapper_data_attributes
            @storage_login_button_options = storage_login_button_options

            super(**system_arguments)
          end

          def to_component
            StorageManualProjectFolderSelection.new(
              input: self,
              project_storage: @project_storage,
              last_project_folders: @last_project_folders,
              storage_login_button_options: @storage_login_button_options,
              wrapper_data_attributes: @wrapper_data_attributes
            )
          end

          def type
            :storage_login_button
          end

          def focusable?
            true
          end
        end
      end
    end
  end
end
