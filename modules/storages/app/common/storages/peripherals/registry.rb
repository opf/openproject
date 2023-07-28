module Storages
  module Peripherals
    class Registry
      extend Dry::Container::Mixin
    end

    Registry.import StorageInteraction::Nextcloud::Queries
  end
end
