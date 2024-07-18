# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        class StorageLoginButtonInput < Primer::Forms::Dsl::Input
          attr_reader :name, :label

          def initialize(storage_login_button_options:, **system_arguments)
            @storage_login_button_options = storage_login_button_options

            super(**system_arguments)
          end

          def to_component
            StorageLoginButton.new(input: self, storage_login_button_options: @storage_login_button_options)
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
