# frozen_string_literal: true

#-- copyright
#++

module Storages
  module Peripherals
    module StorageInteraction
      module Inputs
        class UploadDataContract < Dry::Validation::Contract
          params do
            required(:folder_id).filled(:string)
            required(:file_name).filled(:string)
          end
        end
      end
    end
  end
end
