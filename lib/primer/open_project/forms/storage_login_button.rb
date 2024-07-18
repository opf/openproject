module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class StorageLoginButton < Primer::Forms::BaseComponent
        include AngularHelper

        delegate :builder, :form, to: :@input

        def initialize(input:, storage_login_button_options:)
          super()
          @input = input
          @storage_login_button_options = storage_login_button_options
        end
      end
    end
  end
end
