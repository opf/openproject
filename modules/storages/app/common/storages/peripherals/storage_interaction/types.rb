# frozen_string_literal: true

#-- copyright
#++

module Storages
  module Peripherals
    module StorageInteraction
      module Types
        include Dry::Types()

        ParentFolderType = Constructor(ParentFolder, ParentFolder.method(:build))
      end
    end
  end
end
